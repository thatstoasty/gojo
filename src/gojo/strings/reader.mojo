from utils import StringSlice, Span
from os import abort
from algorithm.memory import parallel_memcpy
from memory import UnsafePointer
import ..io


@value
struct Reader(
    Writable,
    Sized,
    io.Reader,
    io.ByteScanner,
    io.Seeker,
):
    var _data: String
    """String to read from."""
    var _index: Int
    """Current reading index."""

    fn __init__(inout self, data: String = ""):
        self._data = data
        self._index = 0

    fn __len__(self) -> Int:
        """Returns the number of bytes of the unread portion of the string."""
        if self._index >= len(self._data):
            return 0

        return len(self._data) - self._index

    fn as_bytes(ref [_]self) -> Span[Byte, __origin_of(self._data)]:
        """Returns a reference to the unread data of the `Reader`."""
        return self._data.as_bytes()[self._index :]

    fn size(self) -> Int:
        """Returns the original length of the underlying string."""
        return len(self._data)

    fn write_to[W: Writer](self, inout writer: W):
        writer.write_bytes(self._data.as_bytes())

    fn _read(inout self, dest: UnsafePointer[Byte], capacity: Int) raises -> Int:
        """Reads from the internal buffer into the destination buffer.

        Args:
            dest: The destination buffer to read into.
            capacity: The capacity of the destination buffer.

        Returns:
            Int: The number of bytes read into dest.
        """
        if self._index >= len(self._data):
            raise io.EOF

        # Copy the data of the internal buffer from offset to len(buf) into the destination buffer at the given index.
        var bytes_to_write = self.as_bytes()
        var count = min(len(bytes_to_write), capacity)
        parallel_memcpy(dest, bytes_to_write.unsafe_ptr(), count)
        self._index += count
        return count

    fn read(inout self, inout dest: List[Byte, True]) raises -> Int:
        """Reads from the internal buffer into the destination buffer.

        Args:
            dest: The destination buffer to read into.

        Returns:
            Int: The number of bytes read into dest.
        """
        if self._index >= len(self._data):
            raise io.EOF
        if dest.size == dest.capacity:
            raise Error("strings.Reader.read: no space left in destination buffer.")

        bytes_read = self._read(dest.unsafe_ptr().offset(dest.size), dest.capacity - dest.size)
        dest.size += bytes_read
        return bytes_read

    fn read_byte(inout self) raises -> Byte:
        """Reads the next byte from the underlying _data."""
        if self._index >= len(self._data):
            raise io.EOF

        result = self._data.as_bytes()[self._index]
        self._index += 1
        return result

    fn unread_byte(inout self) raises -> None:
        """Unreads the last byte read. Only the most recent byte read can be unread."""
        if self._index <= 0:
            raise Error("strings.Reader.unread_byte: at beginning of _data")

        self._index -= 1

    fn seek(inout self, offset: Int, whence: Int) raises -> Int:
        """Seeks to a new position in the underlying _data. The next read will start from that position.

        Args:
            offset: The offset to seek to.
            whence: The seek mode. It can be one of `io.SEEK_START`, `io.SEEK_CURRENT`, or `io.SEEK_END`.

        Returns:
            The new position in the _data.
        """
        position = 0

        if whence == io.SEEK_START:
            position = offset
        elif whence == io.SEEK_CURRENT:
            position = self._index + offset
        elif whence == io.SEEK_END:
            position = len(self._data) + offset
        else:
            raise Error("strings.Reader.seek: invalid whence")

        if position < 0:
            raise Error("strings.Reader.seek: negative position")

        self._index = position
        return position

    fn write_to[W: io.Writer, //](inout self, inout writer: W) raises -> Int:
        """Writes the remaining portion of the underlying _data to the provided writer.

        Args:
            writer: The writer to write the remaining portion of the _data to.

        Returns:
            The number of bytes written to the writer.
        """
        if self._index >= len(self._data):
            raise io.EOF

        writer.write_bytes(self._data.as_bytes())
        self._index += len(self)
        return len(self)

    fn reset(inout self, data: String):
        """Resets the `Reader` to be reading from the beginning of the provided `data`.

        Args:
            data: The data to read from.
        """
        self._data = data
        self._index = 0

    fn read_until_delimiter(inout self, delimiter: String = "\n") -> StringSlice[__origin_of(self)]:
        """Reads from the underlying `data` until a delimiter is found.
        The delimiter is not included in the returned `data` slice.

        Returns:
            The `data` slice containing the bytes read until the delimiter.
        """
        start = self._index
        bytes = self._data.as_bytes()
        while self._index < len(self._data):
            if bytes[self._index] == ord(delimiter):
                break
            self._index += 1

        self._index += 1
        return StringSlice[__origin_of(self)](
            unsafe_from_utf8_ptr=self._data.unsafe_ptr() + start, len=self._index - start - 1
        )
