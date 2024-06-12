import ..io
from ..builtins import cap, copy, Byte, panic, index_byte
from algorithm.memory import parallel_memcpy


alias Rune = Int32

# SMALL_BUFFER_SIZE is an initial allocation minimal capacity.
alias SMALL_BUFFER_SIZE: Int = 64

# The ReadOp constants describe the last action performed on
# the buffer, so that unread_rune and unread_byte can check for
# invalid usage. op_read_runeX constants are chosen such that
# converted to Int they correspond to the rune size that was read.
alias ReadOp = Int8

# Don't use iota for these, as the values need to correspond with the
# names and comments, which is easier to see when being explicit.
alias OP_READ: ReadOp = -1  # Any other read operation.
alias OP_INVALID: ReadOp = 0  # Non-read operation.
alias OP_READ_RUNE1: ReadOp = 1  # read rune of size 1.
alias OP_READ_RUNE2: ReadOp = 2  # read rune of size 2.
alias OP_READ_RUNE3: ReadOp = 3  # read rune of size 3.
alias OP_READ_RUNE4: ReadOp = 4  # read rune of size 4.

alias MAX_INT: Int = 2147483647
# MIN_READ is the minimum slice size passed to a read call by
# [Buffer.read_from]. As long as the [Buffer] has at least MIN_READ bytes beyond
# what is required to hold the contents of r, read_from will not grow the
# underlying buffer.
alias MIN_READ: Int = 512

# ERR_TOO_LARGE is passed to panic if memory cannot be allocated to store data in a buffer.
alias ERR_TOO_LARGE = "buffer.Buffer: too large"
alias ERR_NEGATIVE_READ = "buffer.Buffer: reader returned negative count from read"
alias ERR_SHORT_WRITE = "short write"


struct Buffer(
    Stringable,
    Sized,
    io.Reader,
    io.Writer,
    io.StringWriter,
    io.ByteWriter,
    io.ByteReader,
):
    var data: DTypePointer[DType.uint8]  # contents are the bytes buf[off : len(buf)]
    var size: Int
    var capacity: Int
    var offset: Int  # read at &buf[off], write at &buf[len(buf)]
    var last_read: ReadOp  # last read operation, so that unread* can work correctly.

    @always_inline
    fn __init__(inout self):
        self.capacity = 4096
        self.size = 0
        self.data = DTypePointer[DType.uint8]().alloc(4096)
        self.offset = 0
        self.last_read = OP_INVALID

    @always_inline
    fn __init__(inout self, owned buf: List[Byte]):
        self.capacity = buf.capacity
        self.size = buf.size
        self.data = buf.steal_data()
        self.offset = 0
        self.last_read = OP_INVALID

    @always_inline
    fn __init__(inout self, owned data: DTypePointer[DType.uint8], capacity: Int, size: Int):
        self.capacity = capacity
        self.size = size
        self.data = data
        self.offset = 0
        self.last_read = OP_INVALID

    @always_inline
    fn __moveinit__(inout self, owned other: Self):
        self.data = other.data
        self.size = other.size
        self.capacity = other.capacity
        self.offset = other.offset
        self.last_read = other.last_read
        other.data = DTypePointer[DType.uint8]()
        other.size = 0
        other.capacity = 0
        other.offset = 0
        other.last_read = OP_INVALID

    @always_inline
    fn __del__(owned self):
        if self.data:
            self.data.free()

    @always_inline
    fn __len__(self) -> Int:
        """Returns the number of bytes of the unread portion of the buffer.
        self.size - self.offset."""
        return self.size - self.offset

    @always_inline
    fn bytes_ptr(self) -> DTypePointer[DType.uint8]:
        """Returns a pointer holding the unread portion of the buffer."""
        return self.data.offset(self.offset)

    @always_inline
    fn bytes(self) -> List[UInt8]:
        """Returns a list of bytes holding a copy of the unread portion of the buffer."""
        var copy = UnsafePointer[UInt8]().alloc(self.size)
        memcpy(copy, self.data.offset(self.offset), self.size)
        return List[UInt8](unsafe_pointer=copy, size=self.size - self.offset, capacity=self.size - self.offset)

    @always_inline
    fn _resize(inout self, capacity: Int) -> None:
        """
        Resizes the string builder buffer.

        Args:
          capacity: The new capacity of the string builder buffer.
        """
        var new_data = UnsafePointer[UInt8]().alloc(capacity)
        memcpy(new_data, self.data, self.size)
        self.data.free()
        self.data = new_data
        self.capacity = capacity

        return None

    @always_inline
    fn _resize_if_needed(inout self, bytes_to_add: Int):
        # TODO: Handle the case where new_capacity is greater than MAX_INT. It should panic.
        if bytes_to_add > self.capacity - self.size:
            var new_capacity = int(self.capacity * 2)
            if new_capacity < self.capacity + bytes_to_add:
                new_capacity = self.capacity + bytes_to_add
            self._resize(new_capacity)

    @always_inline
    fn __str__(self) -> String:
        """
        Converts the string builder to a string.

        Returns:
          The string representation of the string builder. Returns an empty
          string if the string builder is empty.
        """
        var copy = DTypePointer[DType.uint8]().alloc(self.size)
        memcpy(copy, self.data, self.size)
        return StringRef(copy, self.size)

    @always_inline
    fn render(self: Reference[Self]) -> StringSlice[self.is_mutable, self.lifetime]:
        """
        Return a StringSlice view of the data owned by the builder.
        Slightly faster than __str__, 10-20% faster in limited testing.

        Returns:
          The string representation of the string builder. Returns an empty string if the string builder is empty.
        """
        return StringSlice[self.is_mutable, self.lifetime](unsafe_from_utf8_strref=StringRef(self[].data, self[].size))

    @always_inline
    fn _write(inout self, src: Span[Byte]) -> (Int, Error):
        """
        Appends a byte Span to the builder buffer.

        Args:
          src: The byte array to append.
        """
        self._resize_if_needed(len(src))

        memcpy(self.data.offset(self.size), src._data, len(src))
        self.size += len(src)

        return len(src), Error()

    @always_inline
    fn write(inout self, src: List[Byte]) -> (Int, Error):
        """
        Appends a byte Span to the builder buffer.

        Args:
          src: The byte array to append.
        """
        var span = Span(src)
        return self._write(span)

    @always_inline
    fn write_string(inout self, src: String) -> (Int, Error):
        """
        Appends a string to the builder buffer.

        Args:
          src: The string to append.
        """
        return self._write(src.as_bytes_slice())

    @always_inline
    fn write_byte(inout self, byte: Byte) -> (Int, Error):
        """Appends the byte c to the buffer, growing the buffer as needed.
        The returned error is always nil, but is included to match [bufio.Writer]'s
        write_byte. If the buffer becomes too large, write_byte will panic with
        [ERR_TOO_LARGE].

        Args:
            byte: The byte to write to the buffer.

        Returns:
            The number of bytes written to the buffer.
        """
        self.last_read = OP_INVALID
        self._resize_if_needed(1)
        self.data[self.size] = byte
        self.size += 1

        return 1, Error()

    @always_inline
    fn empty(self) -> Bool:
        """Reports whether the unread portion of the buffer is empty."""
        return self.size <= self.offset

    @always_inline
    fn reset(inout self):
        """Resets the buffer to be empty,
        but it retains the underlying storage for use by future writes.
        reset is the same as [buffer.truncate](0)."""
        if self.data:
            self.data.free()
        self.data = DTypePointer[DType.uint8]().alloc(self.capacity)
        self.size = 0
        self.offset = 0
        self.last_read = OP_INVALID

    @always_inline
    fn read(inout self, inout dest: List[Byte]) -> (Int, Error):
        """Reads the next len(dest) bytes from the buffer or until the buffer
        is drained. The return value n is the number of bytes read. If the
        buffer has no data to return, err is io.EOF (unless len(dest) is zero);
        otherwise it is nil.

        Args:
            dest: The buffer to read into.

        Returns:
            The number of bytes read from the buffer.
        """
        self.last_read = OP_INVALID
        if self.empty():
            # Buffer is empty, reset to recover space.
            self.reset()
            if dest.capacity == 0:
                return 0, Error()
            return 0, Error(io.EOF)

        # Copy the data of the internal buffer from offset to len(buf) into the destination buffer at the given index.
        var bytes_read = copy(
            target=dest, source=self.data, source_start=self.offset, source_end=self.size, target_start=len(dest)
        )
        self.offset += bytes_read

        if bytes_read > 0:
            self.last_read = OP_READ

        return bytes_read, Error()

    @always_inline
    fn read_byte(inout self) -> (Byte, Error):
        """Reads and returns the next byte from the buffer.
        If no byte is available, it returns error io.EOF.
        """
        if self.empty():
            # Buffer is empty, reset to recover space.
            self.reset()
            return Byte(0), Error(io.EOF)

        var byte = self.data[self.offset]
        self.offset += 1
        self.last_read = OP_READ

        return byte, Error()

    @always_inline
    fn unread_byte(inout self) -> Error:
        """Unreads the last byte returned by the most recent successful
        read operation that read at least one byte. If a write has happened since
        the last read, if the last read returned an error, or if the read read zero
        bytes, unread_byte returns an error.
        """
        if self.last_read == OP_INVALID:
            return Error("buffer.Buffer: unread_byte: previous operation was not a successful read")

        self.last_read = OP_INVALID
        if self.offset > 0:
            self.offset -= 1

        return Error()

    @always_inline
    fn read_bytes(inout self, delim: Byte) -> (List[Byte], Error):
        """Reads until the first occurrence of delim in the input,
        returning a slice containing the data up to and including the delimiter.
        If read_bytes encounters an error before finding a delimiter,
        it returns the data read before the error and the error itself (often io.EOF).
        read_bytes returns err != nil if and only if the returned data does not end in
        delim.

        TODO: Because read_slice does not return a reference to the internal buffer data,
        we don't need to copy what read_slice returns into a new list. We can just return
        it directly, since that's already a copy.

        Args:
            delim: The delimiter to read until.

        Returns:
            A List[Byte] struct containing the data up to and including the delimiter.
        """
        return self.read_slice(delim)

    @always_inline
    fn read_slice(inout self, delim: Byte) -> (List[Byte], Error):
        """Like read_bytes but returns a reference to internal buffer data.

        TODO: This does not return a reference, but a copy of the data.

        Args:
            delim: The delimiter to read until.

        Returns:
            A List[Byte] struct containing the data up to and including the delimiter.
        """
        var at_eof = False
        var i = index_byte(bytes=self.bytes_ptr(), size=self.size, delim=delim)
        var end = self.offset + i + 1

        if i < 0:
            end = self.size
            at_eof = True

        var copy = UnsafePointer[UInt8]().alloc(end - self.offset)
        memcpy(copy, self.data.offset(self.offset), end - self.offset)
        var line = List[Byte](unsafe_pointer=copy, size=end - self.offset, capacity=end - self.offset)
        self.offset = end
        self.last_read = OP_READ

        if at_eof:
            return line, Error(io.EOF)

        return line, Error()

    @always_inline
    fn read_string(inout self, delim: Byte) -> (String, Error):
        """Reads until the first occurrence of delim in the input,
        returning a string containing the data up to and including the delimiter.
        If read_string encounters an error before finding a delimiter,
        it returns the data read before the error and the error itself (often io.EOF).
        read_string returns err != nil if and only if the returned data does not end
        in delim.

        Args:
            delim: The delimiter to read until.

        Returns:
            A string containing the data up to and including the delimiter.
        """
        var slice: List[Byte]
        var err: Error
        slice, err = self.read_slice(delim)
        slice.append(0)
        return String(slice), err

    @always_inline
    fn next(inout self, number_of_bytes: Int) raises -> List[Byte]:
        """Returns a slice containing the next n bytes from the buffer,
        advancing the buffer as if the bytes had been returned by [Buffer.read].
        If there are fewer than n bytes in the buffer, next returns the entire buffer.
        The slice is only valid until the next call to a read or write method.

        Args:
            number_of_bytes: The number of bytes to read from the buffer.

        Returns:
            A slice containing the next n bytes from the buffer.
        """
        self.last_read = OP_INVALID
        var m = len(self)
        var bytes_to_read = number_of_bytes
        if bytes_to_read > m:
            bytes_to_read = m

        var copy = UnsafePointer[UInt8]().alloc(bytes_to_read)
        memcpy(copy, self.data.offset(self.offset), bytes_to_read)
        var line = List[Byte](unsafe_pointer=copy, size=bytes_to_read, capacity=bytes_to_read)
        self.offset += bytes_to_read
        if bytes_to_read > 0:
            self.last_read = OP_READ

        return line

    fn write_to[W: io.Writer](inout self, inout writer: W) -> (Int64, Error):
        """Writes data to w until the buffer is drained or an error occurs.
        The return value n is the number of bytes written; it always fits into an
        Int, but it is int64 to match the io.WriterTo trait. Any error
        encountered during the write is also returned.

        Args:
            writer: The writer to write to.

        Returns:
            The number of bytes written to the writer.
        """
        self.last_read = OP_INVALID
        var bytes_to_write = len(self)
        var total_bytes_written: Int64 = 0

        if bytes_to_write > 0:
            # TODO: Replace usage of this intermediate slice when normal slicing, once slice references work.
            var byte_count = bytes_to_write - self.offset
            var bytes_written: Int
            var err: Error
            var copy = UnsafePointer[UInt8]().alloc(byte_count)
            memcpy(copy, self.data.offset(self.offset), byte_count)
            var line = List[Byte](unsafe_pointer=copy, size=byte_count, capacity=byte_count)

            bytes_written, err = writer.write(line)
            if bytes_written > bytes_to_write:
                panic("bytes.Buffer.write_to: invalid write count")

            self.offset += bytes_written
            total_bytes_written = Int64(bytes_written)

            var err_message = str(err)
            if err_message != "":
                return total_bytes_written, err

            # all bytes should have been written, by definition of write method in io.Writer
            if bytes_written != bytes_to_write:
                return total_bytes_written, Error(ERR_SHORT_WRITE)

        # Buffer is now empty; reset.
        self.reset()
        return total_bytes_written, Error()


fn new_buffer() -> Buffer:
    """Creates and initializes a new [Buffer] using buf as its`
    initial contents. The new [Buffer] takes ownership of buf, and the
    caller should not use buf after this call. new_buffer is intended to
    prepare a [Buffer] to read existing data. It can also be used to set
    the initial size of the internal buffer for writing. To do that,
    buf should have the desired capacity but a length of zero.

    In most cases, new([Buffer]) (or just declaring a [Buffer] variable) is
    sufficient to initialize a [Buffer].
    """
    var b = List[Byte](capacity=io.BUFFER_SIZE)
    return Buffer(b^)


fn new_buffer(owned buf: List[Byte]) -> Buffer:
    """Creates and initializes a new [Buffer] using buf as its`
    initial contents. The new [Buffer] takes ownership of buf, and the
    caller should not use buf after this call. new_buffer is intended to
    prepare a [Buffer] to read existing data. It can also be used to set
    the initial size of the internal buffer for writing. To do that,
    buf should have the desired capacity but a length of zero.

    In most cases, new([Buffer]) (or just declaring a [Buffer] variable) is
    sufficient to initialize a [Buffer].

    Args:
        buf: The bytes to use as the initial contents of the buffer.

    Returns:
        A new [Buffer] initialized with the provided bytes.
    """
    return Buffer(buf^)


fn new_buffer(owned s: String) -> Buffer:
    """Creates and initializes a new [Buffer] using string s as its
    initial contents. It is intended to prepare a buffer to read an existing
    string.

    In most cases, new([Buffer]) (or just declaring a [Buffer] variable) is
    sufficient to initialize a [Buffer].

    Args:
        s: The string to use as the initial contents of the buffer.

    Returns:
        A new [Buffer] initialized with the provided string.
    """
    var bytes_buffer = List[Byte](s.as_bytes())
    return Buffer(bytes_buffer^)
