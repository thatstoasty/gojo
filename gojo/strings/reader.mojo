import ..io
from ..builtins import Bytes, Byte, copy


@value
struct Reader(Sized, io.Reader, io.ReaderAt, io.ByteReader, io.ByteScanner, io.Seeker, io.WriterTo):
    """A Reader that implements the [io.Reader], [io.ReaderAt], [io.ByteReader], [io.ByteScanner], [io.Seeker], and [io.WriterTo] traits
    by reading from a string. The zero value for Reader operates like a Reader of an empty string."""

    var string: String
    var read_pos: Int64 # current reading index
    var prev_rune: Int   # index of previous rune; or < 0

    fn __init__(inout self, string: String = ""):
        self.string = string
        self.read_pos = 0
        self.prev_rune = -1

    fn __len__(self) -> Int:
        """Returns the number of bytes of the unread portion of the string.
        
        Returns:
            int: the number of bytes of the unread portion of the string.
        """
        if self.read_pos >= Int64(len(self.string)):
            return 0
        
        return int(Int64(len(self.string)) - self.read_pos)

    fn size(self) -> Int64:
        """Returns the original length of the underlying string.
        size is the number of bytes available for reading via [Reader.read_at].
        The returned value is always the same and is not affected by calls
        to any other method.

        Returns:
            The original length of the underlying string.
        """
        return Int64(len(self.string)) 

    fn read(inout self, inout dest: Bytes) raises -> Int:
        """Reads from the underlying string into the provided Bytes object.
        Implements the [io.Reader] trait.
        
        Args:
            dest: The destination Bytes object to read into.
        
        Returns:
            The number of bytes read into dest.
        """
        if self.read_pos >= Int64(len(self.string)):
            raise Error(io.EOF)
        
        self.prev_rune = -1
        var bytes_written = copy(dest, self.string[self.read_pos:])
        self.read_pos += Int64(bytes_written)
        return bytes_written

    fn read_at(self, inout dest: Bytes, off: Int64) raises -> Int:
        """Reads from the Reader into the dest Bytes starting at the offset off.
        It returns the number of bytes read into dest and an error if any.
        Implements the [io.ReaderAt] trait.

        Args:
            dest: The destination Bytes object to read into.
            off: The byte offset to start reading from.

        Returns:
            The number of bytes read into dest.
        """
        # cannot modify state - see io.ReaderAt
        if off < 0:
            raise Error("strings.Reader.read_at: negative offset")
        
        if off >= Int64(len(self.string)):
            raise Error(io.EOF)
        
        var copied_elements_count = copy(dest, self.string[off:])
        if copied_elements_count < len(dest):
            raise Error(io.EOF)
        
        return copied_elements_count

    fn read_byte(inout self) raises -> Byte:
        """Reads the next byte from the underlying string.
        Implements the [io.ByteReader] trait.

        Returns:
            The next byte from the underlying string.
        """
        self.prev_rune = -1
        if self.read_pos >= Int64(len(self.string)):
            raise Error(io.EOF)
        
        var b = self.string[int(self.read_pos)]
        self.read_pos += 1
        return ord(b)
    
    fn unread_byte(inout self) raises:
        """Unreads the last byte read. Only the most recent byte read can be unread.
        Implements the [io.ByteScanner] trait.
        """
        if self.read_pos <= 0:
            raise Error("strings.Reader.unread_byte: at beginning of string")
        
        self.prev_rune = -1
        self.read_pos -= 1
    
    # # ReadRune implements the [io.RuneReader] trait.
    # fn ReadRune() (ch rune, size int, err error):
    #     if self.read_pos >= Int64(len(self.string)):
    #         self.prev_rune = -1
    #         return 0, 0, io.EOF
        
    #     self.prev_rune = int(self.read_pos)
    #     if c = self.string[self.read_pos]; c < utf8.RuneSelf:
    #         self.read_pos += 1
    #         return rune(c), 1, nil
        
    #     ch, size = utf8.DecodeRuneInString(self.string[self.read_pos:])
    #     self.read_pos += Int64(size)
    #     return
    

    # # UnreadRune implements the [io.RuneScanner] trait.
    # fn UnreadRune() error:
    #     if self.read_pos <= 0:
    #         return errors.New("strings.Reader.UnreadRune: at beginning of string")
        
    #     if self.prev_rune < 0:
    #         return errors.New("strings.Reader.UnreadRune: previous operation was not ReadRune")
        
    #     self.read_pos = Int64(self.prev_rune)
    #     self.prev_rune = -1
    #     return nil

    fn seek(inout self, offset: Int64, whence: Int) raises -> Int64:
        """Seeks to a new position in the underlying string. The next read will start from that position.
        Implements the [io.Seeker] trait.
        """
        self.prev_rune = -1
        var position: Int64 = 0

        if whence == io.seek_start:
            position = offset
        elif whence == io.seek_current:
            position = self.read_pos + offset
        elif whence == io.seek_end:
            position = Int64(len(self.string)) + offset
        else:
            raise Error("strings.Reader.seek: invalid whence")
        
        if position < 0:
            raise Error("strings.Reader.seek: negative position")
        
        self.read_pos = position
        return position
    
    fn write_to[W: io.Writer](inout self, inout writer: W) raises -> Int64:
        """Writes the remaining portion of the underlying string to the provided writer.
        Implements the [io.WriterTo] trait.

        Args:
            writer: The writer to write the remaining portion of the string to.

        Returns:
            The number of bytes written to the writer.
        """
        self.prev_rune = -1
        if self.read_pos >= Int64(len(self.string)):
            return 0
        
        var chunk_to_write = self.string[self.read_pos:]
        var bytes_written = io.write_string(writer, chunk_to_write)
        if bytes_written > len(chunk_to_write):
            raise Error("strings.Reader.write_to: invalid write_string count")
        
        self.read_pos += Int64(bytes_written)
        if bytes_written != len(chunk_to_write):
            raise Error(io.ErrShortWrite)
        
        return Int64(bytes_written)
    
    fn write_to[W: io.StringWriter](inout self, inout writer: W) raises -> Int64:
        """Writes the remaining portion of the underlying string to the provided writer.
        Implements the [io.WriterTo] trait.

        Args:
            writer: The writer to write the remaining portion of the string to.

        Returns:
            The number of bytes written to the writer.
        """
        self.prev_rune = -1
        if self.read_pos >= Int64(len(self.string)):
            return 0
        
        var chunk_to_write = self.string[self.read_pos:]
        var bytes_written = io.write_string(writer, chunk_to_write)
        if bytes_written > len(chunk_to_write):
            raise Error("strings.Reader.write_to: invalid write_string count")
        
        self.read_pos += Int64(bytes_written)
        if bytes_written != len(chunk_to_write):
            raise Error(io.ErrShortWrite)
        
        return Int64(bytes_written)

    fn reset(inout self, string: String):
        """Resets the [Reader] to be reading from the beginning of the provided string.

        Args:
            string: The string to read from.
        """
        self.string = string
        self.read_pos = 0
        self.prev_rune = -1


fn new_reader(string: String) -> Reader:
    """Returns a new [Reader] reading from the provided string. 
    It is similar to [bytes.new_buffer_string] but more efficient and non-writable.

    Args:
        string: The string to read from.
    """
    return Reader(string)


fn new_default_reader() -> Reader:
    """Returns a new [Reader] reading from the provided string. 
    It is similar to [bytes.new_buffer_string] but more efficient and non-writable.
    """
    return new_reader("")