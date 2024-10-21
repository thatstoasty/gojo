from utils import Span
from os import abort
from algorithm.memory import parallel_memcpy
from memory import UnsafePointer
import ..io


struct Reader(
    Writable,
    Sized,
    io.Reader,
    io.Seeker,
    io.ByteReader,
    io.ByteScanner,
):
    """A Reader implements the io.Reader, io.WriterTo, io.Seeker,
    io.ByteScanner, and io.RuneScanner Interfaces by reading from
    a bytes pointer. Unlike a `Buffer`, a `Reader` is read-only and supports seeking.

    Examples:
    ```mojo
    from gojo.bytes import reader

    var reader = reader.Reader(buffer=String("Hello, World!").as_bytes())
    var dest = List[Byte, True](capacity=16)
    _ = reader.read(dest)
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
    var index: Int
    """Current reading index."""

    fn __init__(inout self, owned buffer: List[Byte, True]):
        """Initializes a new `Reader` with the given List buffer.

        Args:
            buffer: The buffer to read from.
        """
        self._capacity = buffer.capacity
        self._size = buffer.size
        self._data = buffer.steal_data()
        self.index = 0

    fn __init__(inout self, text: String):
        """Initializes a new `Reader` with the given String.

        Args:
            text: The String to initialize the `Reader` with.
        """
        var bytes = List[Byte, True](text.as_bytes())
        self._capacity = bytes.capacity
        self._size = bytes.size
        self._data = bytes.steal_data()
        self.index = 0

    fn __moveinit__(inout self, owned other: Reader):
        self._capacity = other._capacity
        self._size = other._size
        self._data = other._data
        self.index = other.index

        other._data = UnsafePointer[Byte]()
        other._size = 0
        other._capacity = 0
        other.index = 0

    fn __len__(self) -> Int:
        """Returns the number of bytes of the unread portion of the slice."""
        return self._size - int(self.index)

    fn __del__(owned self) -> None:
        """Frees the internal buffer."""
        if self._data:
            self._data.free()

    fn as_bytes(ref [_]self) -> Span[Byte, __origin_of(self)]:
        """Returns the internal data as a Span[Byte]."""
        return Span[Byte, __origin_of(self)](unsafe_ptr=self._data, len=self._size)

    fn write_to[W: Writer](self, inout writer: W):
        writer.write_bytes(self.as_bytes()[self.index :])

    fn _read(inout self, dest: UnsafePointer[Byte], capacity: Int) raises -> Int:
        """Reads from the internal buffer into the destination buffer.

        Args:
            dest: The destination buffer to read into.
            capacity: The capacity of the destination buffer.

        Returns:
            Int: The number of bytes read into dest.
        """
        if self.index >= self._size:
            raise io.EOF

        # Copy the data of the internal buffer from offset to len(buf) into the destination buffer at the given index.
        var bytes_to_write = self.as_bytes()[self.index : self._size]
        var count = min(len(bytes_to_write), capacity)
        parallel_memcpy(dest, bytes_to_write.unsafe_ptr(), count)
        # var bytes_written = copy(dest, bytes_to_write.unsafe_ptr(), len(bytes_to_write))
        self.index += count

        return count

    fn read(inout self, inout dest: List[Byte, True]) raises -> Int:
        """Reads from the internal buffer into the destination buffer.

        Args:
            dest: The destination buffer to read into.

        Returns:
            Int: The number of bytes read into dest.
        """
        var dest_ptr = dest.unsafe_ptr().offset(dest.size)
        bytes_read = self._read(dest_ptr, dest.capacity - dest.size)
        dest.size += bytes_read

        return bytes_read

    fn _read_at(self, inout dest: Span[Byte], off: Int, capacity: Int) raises -> Int:
        """Reads `len(dest)` bytes into `dest` beginning at byte offset `off`.

        Args:
            dest: The destination buffer to read into.
            off: The offset to start reading from.
            capacity: The capacity of the destination buffer.

        Returns:
            The number of bytes read into dest.
        """
        # cannot modify state - see io.ReaderAt
        if off < 0:
            raise Error("bytes.Reader.read_at: negative offset")

        if off >= Int(self._size):
            raise io.EOF

        var unread_bytes = self.as_bytes()[off : self._size]
        var count = min(len(unread_bytes), capacity)
        parallel_memcpy(dest.unsafe_ptr(), unread_bytes.unsafe_ptr(), count)
        # var bytes_written = copy(dest.unsafe_ptr(), unread_bytes.unsafe_ptr(), len(unread_bytes))
        if count < len(dest):
            raise io.EOF

        return count

    fn read_at(self, inout dest: List[Byte, True], off: Int) raises -> Int:
        """Reads `len(dest)` bytes into `dest` beginning at byte offset `off`.

        Args:
            dest: The destination buffer to read into.
            off: The offset to start reading from.

        Returns:
            The number of bytes read into dest.
        """
        var span = Span(dest)
        bytes_read = self._read_at(span, off, dest.capacity)
        dest.size += bytes_read

        return bytes_read

    fn read_byte(inout self) raises -> Byte:
        """Reads and returns a single byte from the internal buffer."""
        if self.index >= self._size:
            raise io.EOF

        var byte = self._data[self.index]
        self.index += 1
        return byte

    fn unread_byte(inout self) raises -> None:
        """Unreads the last byte read by moving the read position back by one."""
        if self.index <= 0:
            raise Error("bytes.Reader.unread_byte: at beginning of buffer.")
        self.index -= 1

    fn seek(inout self, offset: Int, whence: Int) raises -> Int:
        """Moves the read position to the specified `offset` from the specified `whence`.

        Args:
            offset: The offset to move to.
            whence: The reference point for offset.

        Returns:
            The new position in which the next read will start from.
        """
        var position: Int = 0

        if whence == io.SEEK_START:
            position = offset
        elif whence == io.SEEK_CURRENT:
            position = self.index + offset
        elif whence == io.SEEK_END:
            position = self._size + offset
        else:
            raise Error("bytes.Reader.seek: invalid whence")

        if position < 0:
            raise Error("bytes.Reader.seek: negative position")

        self.index = position
        return position

    fn write_to[W: io.Writer](inout self, inout writer: W) raises -> Int:
        """Writes data to `writer` until the buffer is drained or an error occurs.

        Args:
            writer: The writer to write to.

        Returns:
            The number of bytes written and an error if one occurred.
        """
        if self.index >= self._size:
            return 0

        var bytes = self.as_bytes()[self.index : self._size]
        writer.write_bytes(bytes)
        var write_count = len(bytes)

        self.index += write_count
        if write_count != len(bytes):
            raise Error(io.ERR_SHORT_WRITE)

        return write_count

    fn reset(inout self, owned buffer: List[Byte, True]) -> None:
        """Resets the `Reader` to be reading from `buffer`.

        Args:
            buffer: The new buffer to read from.
        """
        self._capacity = buffer.capacity
        self._size = buffer.size
        self._data = buffer.steal_data()
        self.index = 0
