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
    io.ByteReader,
    io.ByteScanner,
    io.Seeker,
):
    var string: String
    """Internal string to read from."""
    var read_pos: Int
    """Current reading index."""

    fn __init__(inout self, string: String = ""):
        self.string = string
        self.read_pos = 0

    fn __len__(self) -> Int:
        """Returns the number of bytes of the unread portion of the string."""
        if self.read_pos >= len(self.string):
            return 0

        return len(self.string) - self.read_pos

    fn size(self) -> Int:
        """Returns the original length of the underlying string.
        `size` is the number of bytes available for reading via `Reader.read_at`.
        The returned value is always the same and is not affected by calls
        to any other method.

        Returns:
            The original length of the underlying string.
        """
        return len(self.string)

    fn write_to[W: Writer](self, inout writer: W):
        writer.write_bytes(self.string.as_bytes()[self.read_pos :])

    fn _read(inout self, dest: UnsafePointer[Byte], capacity: Int) raises -> Int:
        """Reads from the underlying string into the provided `dest` buffer.

        Args:
            dest: The destination buffer to read into.
            capacity: The capacity of the destination buffer.

        Returns:
            The number of bytes read into dest.
        """
        if self.read_pos >= len(self.string):
            raise io.EOF

        bytes_to_read = self.string.as_bytes()[self.read_pos :]
        count = min(len(bytes_to_read), capacity)
        parallel_memcpy(dest, bytes_to_read.unsafe_ptr(), count)
        self.read_pos += count
        return count

    fn read(inout self, inout dest: List[Byte, True]) raises -> Int:
        """Reads from the underlying string into the provided `dest` buffer.

        Args:
            dest: The destination buffer to read into.

        Returns:
            The number of bytes read into dest.
        """
        if dest.size == dest.capacity:
            raise Error("strings.Reader.read: no space left in destination buffer.")

        bytes_read = self._read(dest.unsafe_ptr().offset(dest.size), dest.capacity - dest.size)
        dest.size += bytes_read

        return bytes_read

    fn read_byte(inout self) raises -> Byte:
        """Reads the next byte from the underlying string."""
        if self.read_pos >= len(self.string):
            raise io.EOF

        b = self.string.as_bytes()[self.read_pos]
        self.read_pos += 1
        return b

    fn unread_byte(inout self) raises -> None:
        """Unreads the last byte read. Only the most recent byte read can be unread."""
        if self.read_pos <= 0:
            raise Error("strings.Reader.unread_byte: at beginning of string")

        self.read_pos -= 1

    fn seek(inout self, offset: Int, whence: Int) raises -> Int:
        """Seeks to a new position in the underlying string. The next read will start from that position.

        Args:
            offset: The offset to seek to.
            whence: The seek mode. It can be one of `io.SEEK_START`, `io.SEEK_CURRENT`, or `io.SEEK_END`.

        Returns:
            The new position in the string.
        """
        position = 0

        if whence == io.SEEK_START:
            position = offset
        elif whence == io.SEEK_CURRENT:
            position = self.read_pos + offset
        elif whence == io.SEEK_END:
            position = Int(len(self.string)) + offset
        else:
            raise Error("strings.Reader.seek: invalid whence")

        if position < 0:
            raise Error("strings.Reader.seek: negative position")

        self.read_pos = position
        return position

    fn write_to[W: io.Writer, //](inout self, inout writer: W) raises -> Int:
        """Writes the remaining portion of the underlying string to the provided writer.

        Args:
            writer: The writer to write the remaining portion of the string to.

        Returns:
            The number of bytes written to the writer.
        """
        if self.read_pos >= len(self.string):
            raise io.EOF

        chunk_to_write = self.string.as_bytes()[self.read_pos :]
        writer.write_bytes(chunk_to_write)
        bytes_written = len(chunk_to_write)

        self.read_pos += bytes_written
        return bytes_written

    fn reset(inout self, string: String):
        """Resets the [Reader] to be reading from the beginning of the provided string.

        Args:
            string: The string to read from.
        """
        self.string = string
        self.read_pos = 0

    fn read_until_delimiter(inout self, delimiter: String = "\n") -> StringSlice[__origin_of(self)]:
        """Reads from the underlying string until a delimiter is found.
        The delimiter is not included in the returned string slice.

        Returns:
            The string slice containing the bytes read until the delimiter.
        """
        start = self.read_pos
        bytes = self.string.as_bytes()
        while self.read_pos < len(self.string):
            if bytes[self.read_pos] == ord(delimiter):
                break
            self.read_pos += 1

        self.read_pos += 1
        return StringSlice[__origin_of(self)](
            unsafe_from_utf8_ptr=self.string.unsafe_ptr() + start, len=self.read_pos - start - 1
        )
