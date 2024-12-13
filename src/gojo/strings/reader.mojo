from utils import StringSlice
from os import abort
from algorithm.memory import parallel_memcpy
from memory import UnsafePointer, Span
import ..io


@value
struct Reader(
    Writable,
    Sized,
    io.Reader,
    io.ByteScanner,
    io.Seeker,
):
    """Reads data from a string."""

    var _data: String
    """String to read from."""
    var _index: Int
    """Current reading index."""

    fn __init__(out self, data: String = ""):
        """Initializes a new `Reader` instance.

        Args:
            data: The data to read from.
        """
        self._data = data
        self._index = 0

    fn __len__(self) -> Int:
        """Returns the number of bytes of the unread portion of the string.

        Returns:
            The number of bytes of the unread portion of the string.
        """
        if self._index >= len(self._data):
            return 0

        return len(self._data) - self._index

    fn as_bytes(ref self) -> Span[Byte, __origin_of(self._data)]:
        """Returns a reference to the unread data of the `Reader`.

        Returns:
            The unread portion of the data as a `Span[Byte]`.
        """
        return self._data.as_bytes()[self._index :]

    fn size(self) -> Int:
        """Returns the original length of the underlying string.

        Returns:
            The original length of the underlying string.
        """
        return len(self._data)

    fn write_to[W: Writer, //](self, mut writer: W) -> None:
        """Writes the remaining portion of the underlying data to the provided writer.

        Parameters:
            W: The type of writer.

        Args:
            writer: The writer to write the remaining portion of the data to.
        """
        writer.write_bytes(self._data.as_bytes())

    fn _read(mut self, dest: UnsafePointer[Byte], capacity: Int) raises -> Int:
        """Reads from the internal buffer into the destination buffer.

        Args:
            dest: The destination buffer to read into.
            capacity: The capacity of the destination buffer.

        Returns:
            Int: The number of bytes read into dest.

        Raises:
            Error: If the index is equal to or greater then the length of data. IE EOF.
        """
        if self._index >= len(self._data):
            raise io.EOF

        # Copy the data of the internal buffer from offset to len(buf) into the destination buffer at the given index.
        var bytes_to_write = self.as_bytes()
        var count = min(len(bytes_to_write), capacity)
        parallel_memcpy(dest, bytes_to_write.unsafe_ptr(), count)
        self._index += count
        return count

    fn read(mut self, mut dest: List[Byte, True]) raises -> Int:
        """Reads from the internal buffer into the destination buffer.

        Args:
            dest: The destination buffer to read into.

        Returns:
            Int: The number of bytes read into dest.

        Raises:
            Error: If the destination buffer is full.
        """
        if self._index >= len(self._data):
            raise io.EOF
        if dest.size == dest.capacity:
            raise Error("strings.Reader.read: no space left in destination buffer.")

        bytes_read = self._read(dest.unsafe_ptr().offset(len(dest)), dest.capacity - dest.size)
        dest.size += bytes_read
        return bytes_read

    fn read_byte(mut self) raises -> Byte:
        """Reads the next byte from the underlying data.

        Returns:
            The byte read.

        Raises:
            Error: If the reader is at the end of the data.
        """
        if self._index >= len(self._data):
            raise io.EOF

        result = self._data.as_bytes()[self._index]
        self._index += 1
        return result

    fn unread_byte(mut self) raises -> None:
        """Unreads the last byte read. Only the most recent byte read can be unread.

        Raises:
            Error: If the reader is at the beginning of the data.
        """
        if self._index <= 0:
            raise Error("strings.Reader.unread_byte: at beginning of data")

        self._index -= 1

    fn seek(mut self, offset: Int, whence: Int) raises -> Int:
        """Seeks to a new position in the underlying data. The next read will start from that position.

        Args:
            offset: The offset to seek to.
            whence: The seek mode. It can be one of `io.SEEK_START`, `io.SEEK_CURRENT`, or `io.SEEK_END`.

        Returns:
            The new position in the _data.

        Raises:
            Error: If the whence is invalid or the position is negative.
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

    fn write_to[W: Writer, //](mut self, mut writer: W) raises -> Int:
        """Writes the remaining portion of the underlying _data to the provided writer.

        Parameters:
            W: The type of writer.

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

    fn reset(mut self, data: String) -> None:
        """Resets the `Reader` to be reading from the beginning of the provided `data`.

        Args:
            data: The data to read from.
        """
        self._data = data
        self._index = 0

    fn read_until_delimiter(mut self, delimiter: String = "\n") -> StringSlice[__origin_of(self)]:
        """Reads from the underlying `data` until a delimiter is found.
        The delimiter is not included in the returned `data` slice.

        Args:
            delimiter: The delimiter to read until.

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
        return StringSlice[__origin_of(self)](ptr=self._data.unsafe_ptr() + start, length=self._index - start - 1)
