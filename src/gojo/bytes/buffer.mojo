from utils import StringSlice, Span
from algorithm.memory import parallel_memcpy
from memory import UnsafePointer
from os import abort
import ..io
from ..bytes import index_byte


alias SMALL_BUFFER_SIZE: Int = 64
"""Initial allocation minimal capacity."""

alias ReadOp = Int8
"""The ReadOp constants describe the last action performed on
the buffer, so that unread_rune and unread_byte can check for
invalid usage. op_read_runeX constants are chosen such that
converted to Int they correspond to the rune size that was read."""

alias OP_READ: ReadOp = -1
"""Any other read operation."""
alias OP_INVALID: ReadOp = 0
"""Non-read operation."""
alias OP_READ_RUNE1: ReadOp = 1
"""Read rune of size 1."""
alias OP_READ_RUNE2: ReadOp = 2
"""Read rune of size 2."""
alias OP_READ_RUNE3: ReadOp = 3
"""Read rune of size 3."""
alias OP_READ_RUNE4: ReadOp = 4
"""Read rune of size 4."""

alias MAX_INT: Int = 2147483647
alias MIN_READ: Int = 512
"""MIN_READ is the minimum slice size passed to a read call by
[Buffer.read_from]. As long as the [Buffer] has at least MIN_READ bytes beyond
what is required to hold the contents of r, read_from will not grow the
underlying buffer."""

alias ERR_TOO_LARGE = "buffer.Buffer: too large"
"""ERR_TOO_LARGE is passed to panic if memory cannot be allocated to store data in a buffer."""
alias ERR_NEGATIVE_READ = "buffer.Buffer: reader returned negative count from read"
alias ERR_SHORT_WRITE = "short write"


struct Buffer(
    Writer,
    Writable,
    Stringable,
    Sized,
    io.Reader,
    io.ByteReader,
):
    """A Buffer is a variable-sized buffer of bytes with Read and Write methods.

    Examples:
    ```mojo
    import gojo.bytes
    var buf = bytes.Buffer(capacity=16)
    _ = buf.write("Hello, World!")

    var dest = List[Byte, True](capacity=16)
    _ = buf.read(dest)
    dest.append(0)
    print(String(dest))  # Output: Hello, World!
    ```
    .
    """

    var _data: UnsafePointer[Byte]
    """The contents of the bytes buffer. Active contents are from buf[off : len(buf)]."""
    var _size: Int
    """The number of bytes stored in the buffer."""
    var _capacity: Int
    """The maximum capacity of the buffer, eg the allocation of self._data."""
    var offset: Int  #
    """The read/writer offset of the buffer. read at buf[off], write at buf[len(buf)]."""
    var last_read: ReadOp
    """Last read operation, so that unread* can work correctly."""

    fn __init__(inout self, *, capacity: Int = io.BUFFER_SIZE):
        """Creates a new buffer with the specified capacity.

        Args:
            capacity: The initial capacity of the buffer.
        """
        self._capacity = capacity
        self._size = 0
        self._data = UnsafePointer[Byte]().alloc(capacity)
        self.offset = 0
        self.last_read = OP_INVALID

    fn __init__(inout self, owned buf: List[Byte, True]):
        """Creates a new buffer with List buffer provided.

        Args:
            buf: The List buffer to initialize the buffer with.
        """
        self._capacity = buf.capacity
        self._size = buf.size
        self._data = buf.steal_data()
        self.offset = 0
        self.last_read = OP_INVALID

    fn __init__(inout self, buf: String):
        """Creates a new buffer with String provided.

        Args:
            buf: The String to initialize the buffer with.
        """
        bytes = List[Byte, True](buf.as_bytes())
        self._capacity = bytes.capacity
        self._size = bytes.size
        self._data = bytes.steal_data()
        self.offset = 0
        self.last_read = OP_INVALID

    fn __init__(inout self, *, owned data: UnsafePointer[Byte], capacity: Int, size: Int):
        """Creates a new buffer with UnsafePointer buffer provided.

        Args:
            data: The List buffer to initialize the buffer with.
            capacity: The initial capacity of the buffer.
            size: The number of bytes stored in the buffer.
        """
        self._capacity = capacity
        self._size = size
        self._data = data
        self.offset = 0
        self.last_read = OP_INVALID

    fn __moveinit__(inout self, owned other: Self):
        self._data = other._data
        self._size = other._size
        self._capacity = other._capacity
        self.offset = other.offset
        self.last_read = other.last_read
        other._data = UnsafePointer[Byte]()
        other._size = 0
        other._capacity = 0
        other.offset = 0
        other.last_read = OP_INVALID

    fn __del__(owned self):
        if self._data:
            self._data.free()

    fn __len__(self) -> Int:
        """Returns the number of bytes of the unread portion of the buffer. `self._size - self.offset`."""
        return self._size - self.offset

    fn as_bytes(ref [_]self) -> Span[Byte, __origin_of(self)]:
        """Returns the internal data as a Span[Byte]."""
        return Span[Byte, __origin_of(self)](unsafe_ptr=self._data, len=self._size)

    fn as_string_slice(ref [_]self) -> StringSlice[__origin_of(self)]:
        """
        Return a StringSlice view of the data owned by the builder.

        Returns:
          The string representation of the bytes buffer. Returns an empty string if the bytes buffer is empty.
        """
        return StringSlice[__origin_of(self)](unsafe_from_utf8_ptr=self._data, len=self._size)

    fn _resize(inout self, capacity: Int) -> None:
        """
        Resizes the string builder buffer.

        Args:
          capacity: The new capacity of the string builder buffer.
        """
        new_data = UnsafePointer[Byte]().alloc(capacity)
        parallel_memcpy(new_data, self._data, self._size)
        self._data.free()
        self._data = new_data
        self._capacity = capacity

        return None

    fn _resize_if_needed(inout self, bytes_to_add: Int) -> None:
        """Resizes the buffer if the number of bytes to add exceeds the buffer's capacity.

        Args:
            bytes_to_add: The number of bytes to add to the buffer.
        """
        # TODO: Handle the case where new_capacity is greater than MAX_INT. It should panic.
        if bytes_to_add > self._capacity - self._size:
            new_capacity = int(self._capacity * 2)
            if new_capacity < self._capacity + bytes_to_add:
                new_capacity = self._capacity + bytes_to_add
            self._resize(new_capacity)

    fn __str__(self) -> String:
        """
        Converts the string builder to a string.

        Returns:
          The string representation of the string builder. Returns an empty
          string if the string builder is empty.
        """
        return String.write(self)

    fn write_to[W: Writer](self, inout writer: W):
        writer.write(self.as_string_slice())

    fn consume(inout self, reuse: Bool = False) -> String:
        """
        Transfers the `Buffer`'s data to a string and resets it. Effectively consuming it.

        Args:
            reuse: If `True`, a new internal buffer will be allocated with the same capacity as the previous one.

        Returns:
          The String representation of the `Buffer`. Returns an empty string if the internal buffer is empty.
        """
        var bytes = List[Byte, True](unsafe_pointer=self._data, size=self._size, capacity=self._capacity)
        bytes.append(0)
        var result = String(bytes^)

        if reuse:
            self._data = UnsafePointer[Byte].alloc(self._capacity)
        else:
            self._data = UnsafePointer[Byte]()
        self._size = 0
        return result

    fn write_byte(inout self, byte: Byte):
        """Appends a byte to the buffer.

        Args:
            byte: The byte to append.
        """
        self._resize_if_needed(1)
        self._data[self._size] = byte
        self._size += 1

    @always_inline
    fn write_bytes(inout self, bytes: Span[Byte, _]) -> None:
        """
        Write a `Span[Byte]` to this `Writer`.
        Args:
            bytes: The string slice to write to this Writer. Must NOT be
              null-terminated.
        """
        if len(bytes) == 0:
            return

        self._resize_if_needed(len(bytes))
        parallel_memcpy(self._data.offset(self._size), bytes._data, len(bytes))
        self._size += len(bytes)

    fn write[*Ts: Writable](inout self, *args: *Ts) -> None:
        """Write data to the StringBuilder."""

        @parameter
        fn write_arg[T: Writable](arg: T):
            arg.write_to(self)

        args.each[write_arg]()

    fn empty(self) -> Bool:
        """Reports whether the unread portion of the buffer is empty."""
        return self._size <= self.offset

    fn reset(inout self) -> None:
        """Resets the buffer to be empty."""
        if self._data:
            self._data.free()
        self._data = UnsafePointer[Byte]().alloc(self._capacity)
        self._size = 0
        self.offset = 0
        self.last_read = OP_INVALID

    fn _read(inout self, dest: UnsafePointer[Byte], capacity: Int) raises -> Int:
        """Reads the next `len(dest)` bytes from the buffer or until the buffer
        is drained. The return value `bytes_read` is the number of bytes read.

        If the buffer has no data to return, err is `io.EOF` (unless `len(dest)` is zero);
        otherwise it is empty.

        Args:
            dest: The buffer to read into.
            capacity: The capacity of the destination buffer.

        Returns:
            The number of bytes read from the buffer.
        """
        self.last_read = OP_INVALID
        if self.empty():
            # Buffer is empty, reset to recover space.
            self.reset()
            if capacity == 0:
                return 0
            raise io.EOF

        # Copy the data of the internal buffer from offset to len(buf) into the destination buffer at the given index.
        bytes_to_read = self.as_bytes()[self.offset :]
        count = min(capacity, len(bytes_to_read))
        parallel_memcpy(dest, bytes_to_read.unsafe_ptr(), count)
        self.offset += count

        if count > 0:
            self.last_read = OP_READ

        return count

    fn read(inout self, inout dest: List[Byte, True]) raises -> Int:
        """Reads the next len(dest) bytes from the buffer or until the buffer
        is drained. The return value `bytes_read` is the number of bytes read.

        If the buffer has no data to return, err is `io.EOF` (unless `len(dest)` is zero);
        otherwise it is empty.

        Args:
            dest: The buffer to read into.

        Returns:
            The number of bytes read from the buffer.
        """
        bytes_read = self._read(dest.unsafe_ptr().offset(dest.size), dest.capacity - dest.size)
        dest.size += bytes_read

        return bytes_read

    fn read_byte(inout self) raises -> Byte:
        """Reads and returns the next byte from the buffer. If no byte is available, it returns error `io.EOF`.

        Returns:
            The next byte from the buffer.
        """
        if self.empty():
            # Buffer is empty, reset to recover space.
            self.reset()
            raise io.EOF

        byte = self._data[self.offset]
        self.offset += 1
        self.last_read = OP_READ

        return byte

    fn unread_byte(inout self) raises -> None:
        """Unreads the last byte returned by the most recent successful read operation that read at least one byte."""
        if self.last_read == OP_INVALID:
            raise Error("buffer.Buffer: unread_byte: previous operation was not a successful read")

        self.last_read = OP_INVALID
        if self.offset > 0:
            self.offset -= 1

    fn read_span(inout self, delim: Byte) raises -> Span[Byte, __origin_of(self)]:
        """Like `read_bytes` but returns a reference to internal buffer data.

        Args:
            delim: The delimiter to read until.

        Returns:
            A span containing the data up to and including the delimiter.
        """
        i = index_byte(self.as_bytes(), delim)
        end = self.offset + i + 1

        err = Error()
        if i < 0:
            end = self._size
            err = Error(io.EOF)

        line = self.as_bytes()[self.offset : end]
        self.offset = end
        self.last_read = OP_READ

        if err:
            raise err

        return line

    fn read_string(inout self, delim: Byte) raises -> String:
        """Reads until the first occurrence of `delim` in the input,
        returning a string containing the data up to and including the delimiter.

        If `read_string` encounters an error before finding a delimiter,
        it returns the data read before the error and the error itself (often `io.EOF`).
        `read_string` returns an error if and only if the returned data does not end
        in `delim`.

        Args:
            delim: The delimiter to read until.

        Returns:
            A string containing the data up to and including the delimiter.
        """
        return StringSlice(unsafe_from_utf8=self.read_span(delim))

    fn next(inout self, number_of_bytes: Int) -> Span[Byte, __origin_of(self)]:
        """Returns a Span containing the next n bytes from the buffer,
        advancing the buffer as if the bytes had been returned by `Buffer.read`.

        If there are fewer than n bytes in the buffer, `next` returns the entire buffer.

        Args:
            number_of_bytes: The number of bytes to read from the buffer.

        Returns:
            A slice containing the next n bytes from the buffer.
        """
        self.last_read = OP_INVALID
        bytes_remaining = len(self)
        bytes_to_read = number_of_bytes
        if bytes_to_read > bytes_remaining:
            bytes_to_read = bytes_remaining

        data = self.as_bytes()[self.offset : self.offset + bytes_to_read]

        self.offset += bytes_to_read
        if bytes_to_read > 0:
            self.last_read = OP_READ

        return data

    fn write_to[W: Writer](inout self, inout writer: W) raises -> Int:
        """Writes data to `writer` until the buffer is drained or an error occurs.
        The return value `total_bytes_written` is the number of bytes written; Any error
        encountered during the write is also returned.

        Args:
            writer: The writer to write to.

        Returns:
            The number of bytes written to the writer.
        """
        self.last_read = OP_INVALID
        byte_count = len(self)
        total_bytes_written = 0

        if byte_count > 0:
            bytes_to_write = self.as_bytes()[self.offset :]
            writer.write_bytes(bytes_to_write)
            bytes_written = len(bytes_to_write)
            if bytes_written > byte_count:
                abort("bytes.Buffer.write_to: invalid write count")

            self.offset += bytes_written
            total_bytes_written = bytes_written

            # all bytes should have been written, by definition of write method
            if bytes_written != byte_count:
                raise ERR_SHORT_WRITE

        # Buffer is now empty; reset.
        self.reset()
        return total_bytes_written
