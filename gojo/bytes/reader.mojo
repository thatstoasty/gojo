from collections.optional import Optional
from ..builtins import cap, copy
from ..builtins._bytes import Bytes, Byte
import ..io


@value
struct Reader(
    Copyable,
    Sized,
    io.Reader,
    io.ReaderAt,
    io.WriterTo,
    io.Seeker,
    io.ByteReader,
    io.ByteScanner,
):
    """A Reader implements the io.Reader, io.ReaderAt, io.WriterTo, io.Seeker,
    io.ByteScanner, and io.RuneScanner Interfaces by reading from
    a byte slice.
    Unlike a [Buffer], a Reader is read-only and supports seeking.
    The zero value for Reader operates like a Reader of an empty slice.
    """

    var buffer: Bytes
    var index: Int64  # current reading index
    var prev_rune: Int  # index of previous rune; or < 0

    fn __len__(self) -> Int:
        """len returns the number of bytes of the unread portion of the
        slice."""
        if self.index >= len(self.buffer):
            return 0

        return int(len(self.buffer) - self.index)

    fn size(self) -> Int:
        """Returns the original length of the underlying byte slice.
        Size is the number of bytes available for reading via [Reader.ReadAt].
        The result is unaffected by any method calls except [Reader.Reset]."""
        return len(self.buffer)

    fn read(inout self, inout dest: Bytes) raises -> Int:
        """Reads from the internal buffer into the dest Bytes struct.
        Implements the [io.Reader] Interface.

        Args:
            dest: The destination Bytes struct to read into.

        Returns:
            Int: The number of bytes read into dest."""
        if self.index >= len(self.buffer):
            raise Error(io.EOF)

        self.prev_rune = -1
        var unread_bytes = self.buffer[int(self.index) :]
        var n = copy(dest, unread_bytes)

        self.index += n
        return n

    fn read_at(self, inout dest: Bytes, off: Int64) raises -> Int:
        """Reads len(dest) bytes into dest beginning at byte offset off.
        Implements the [io.ReaderAt] Interface.

        Args:
            dest: The destination Bytes struct to read into.
            off: The offset to start reading from.

        Returns:
            Int: The number of bytes read into dest.
        """
        # cannot modify state - see io.ReaderAt
        if off < 0:
            raise Error("bytes.Reader.read_at: negative offset")

        if off >= Int64(len(self.buffer)):
            raise Error(io.EOF)

        var unread_bytes = self.buffer[int(off) :]
        var bytes_written = copy(dest, unread_bytes)
        if bytes_written < len(dest):
            raise Error(io.EOF)

        return bytes_written

    fn read_byte(inout self) raises -> Byte:
        """Reads and returns a single byte from the internal buffer. Implements the [io.ByteReader] Interface.
        """
        self.prev_rune = -1
        if self.index >= len(self.buffer):
            raise Error(io.EOF)

        var byte = self.buffer[int(self.index)]
        self.index += 1
        return byte

    fn unread_byte(inout self) raises:
        """Unreads the last byte read by moving the read position back by one.
        Complements [Reader.read_byte] in implementing the [io.ByteScanner] Interface.
        """
        if self.index <= 0:
            raise Error("bytes.Reader.unread_byte: at beginning of slice")

        self.prev_rune = -1
        self.index -= 1

    # # read_rune implements the [io.RuneReader] Interface.
    # fn read_rune(self) (ch rune, size Int, err error):
    #     if self.index >= Int64(len(self.buffer)):
    #         self.prev_rune = -1
    #         return 0, 0, io.EOF

    #     self.prev_rune = Int(self.index)
    #     if c := self.buffer[self.index]; c < utf8.RuneSelf:
    #         self.index+= 1
    #         return rune(c), 1, nil

    #     ch, size = utf8.DecodeRune(self.buffer[self.index:])
    #     self.index += Int64(size)
    #     return

    # # unread_rune complements [Reader.read_rune] in implementing the [io.RuneScanner] Interface.
    # fn unread_rune(self) error:
    #     if self.index <= 0:
    #         return errors.New("bytes.Reader.unread_rune: at beginning of slice")

    #     if self.prev_rune < 0:
    #         return errors.New("bytes.Reader.unread_rune: previous operation was not read_rune")

    #     self.index = Int64(self.prev_rune)
    #     self.prev_rune = -1
    #     return nil

    fn seek(inout self, offset: Int64, whence: Int) raises -> Int64:
        """Moves the read position to the specified offset from the specified whence.
        Implements the [io.Seeker] Interface.

        Args:
            offset: The offset to move to.
            whence: The reference point for offset.

        Returns:
            The new position in which the next read will start from.
        """
        self.prev_rune = -1
        var position: Int64 = 0

        if whence == io.SEEK_START:
            position = offset
        elif whence == io.SEEK_CURRENT:
            position = self.index + offset
        elif whence == io.SEEK_END:
            position = len(self.buffer) + offset
        else:
            raise Error("bytes.Reader.seek: invalid whence")

        if position < 0:
            raise Error("bytes.Reader.seek: negative position")

        self.index = position
        return position

    fn write_to[W: io.Writer](inout self, inout writer: W) raises -> Int64:
        """Writes data to w until the buffer is drained or an error occurs.
        implements the [io.WriterTo] Interface.

        Args:
            writer: The writer to write to.
        """
        self.prev_rune = -1
        if self.index >= len(self.buffer):
            return 0

        var b = self.buffer[int(self.index) :]
        var write_count = writer.write(b)
        if write_count > len(b):
            raise Error("bytes.Reader.write_to: invalid Write count")

        self.index += write_count
        if write_count != len(b):
            raise Error(io.ERR_SHORT_WRITE)

        return Int64(write_count)

    fn reset(inout self, buffer: Bytes):
        """Resets the [Reader.Reader] to be reading from b.

        Args:
            buffer: The new buffer to read from.
        """
        self.buffer = buffer
        self.index = 0
        self.prev_rune = -1


fn new_reader(buffer: Bytes) -> Reader:
    """Returns a new [Reader.Reader] reading from b.

    Args:
        buffer: The new buffer to read from.

    """
    return Reader(buffer, 0, -1)
