from utils import Span
from utils.write import MovableWriter
import ..io
from algorithm.memory import parallel_memcpy


# buffered output
struct Writer[W: MovableWriter, //](Sized, io.StringWriter, io.ReaderFrom):
    """Implements buffering for an `io.Writer` object.
    If an error occurs writing to a `Writer`, no more data will be
    accepted and all subsequent writes, and `Writer.flush`, will return the error.

    After all data has been written, the client should call the
    `Writer.flush` method to guarantee all data has been forwarded to
    the underlying `io.Writer`.

    Examples:
    ```mojo
    import gojo.bytes
    import gojo.bufio
    var buf = bytes.Buffer(capacity=16)
    var writer = bufio.Writer(buf^)

    var dest = List[UInt8, True](capacity=16)
    var src = String("Hello, World!")
    _ = writer.write_string(dest)
    ```
    .
    """

    var buf: List[UInt8, True]
    """Internal buffer of bytes."""
    var bytes_written: Int
    """Number of bytes written to the buffer."""
    var writer: W
    """Writer provided by the client."""
    var err: Error
    """Error encountered during writing."""

    fn __init__(
        inout self,
        owned writer: W,
        *,
        capacity: Int = io.BUFFER_SIZE,
    ):
        """Initializes a new buffered writer with the provided writer and buffer capacity.

        Args:
            writer: The writer to buffer.
            capacity: The initial buffer capacity.
        """
        self.buf = List[UInt8, True](capacity=capacity)
        self.bytes_written = 0
        self.writer = writer^
        self.err = Error()

    fn __moveinit__(inout self, owned existing: Self):
        self.buf = existing.buf^
        self.bytes_written = existing.bytes_written
        self.writer = existing.writer^
        self.err = existing.err^

    fn __len__(self) -> Int:
        """Returns the size of the underlying buffer in bytes."""
        return len(self.buf)

    fn as_bytes(ref [_]self) -> Span[UInt8, __origin_of(self.buf)]:
        """Returns the internal data as a Span[UInt8]."""
        return Span[UInt8, __origin_of(self.buf)](unsafe_ptr=self.buf.unsafe_ptr(), len=self.buf.size)

    fn reset(inout self, owned writer: W) -> None:
        """Discards any unflushed buffered data, clears any error, and
        resets the internal buffer to write its output to `writer`.
        Calling `reset` initializes the internal buffer to the default size.

        Args:
            writer: The writer to write to.
        """
        self.err = Error()
        self.bytes_written = 0
        self.writer = writer^

    fn flush(inout self) -> Error:
        """Writes any buffered data to the underlying `Writer`.

        Returns:
            An error if one occurred during writing.
        """
        # Prior to attempting to flush, check if there's a pre-existing error or if there's nothing to flush.
        err = Error()
        if self.err:
            return self.err
        if self.bytes_written == 0:
            return err

        bytes = self.as_bytes()[0 : self.bytes_written]
        bytes_written = len(bytes)
        self.writer.write_bytes(self.as_bytes()[0 : self.bytes_written])

        # If the write was short, set a short write error and try to shift up the remaining bytes.
        if bytes_written < self.bytes_written and not err:
            err = Error(io.ERR_SHORT_WRITE)

        if err:
            if bytes_written > 0 and bytes_written < self.bytes_written:
                temp = self.as_bytes()[bytes_written : self.bytes_written]
                parallel_memcpy(self.buf.unsafe_ptr(), temp.unsafe_ptr(), len(temp))
                self.buf.size += len(temp)

            self.bytes_written -= bytes_written
            self.err = err
            return err

        # Reset the buffer
        self.buf.resize(0)
        self.bytes_written = 0
        return err

    fn available(self) -> Int:
        """Returns how many bytes are unused in the buffer."""
        return self.buf.capacity - len(self.buf)

    fn buffered(self) -> Int:
        """Returns the number of bytes that have been written into the current buffer.

        Returns:
            The number of bytes that have been written into the current buffer.
        """
        return self.bytes_written

    @always_inline
    fn write_bytes(inout self, bytes: Span[Byte, _]) -> None:
        """Writes the contents of `src` into the internal buffer.
        If `total_bytes_written` < `len(src)`, it also returns an error explaining
        why the write is short.

        Args:
            bytes: The bytes to write.
        """
        total_bytes_written = 0
        start = 0
        end = len(bytes)

        # When writing more than the available buffer.
        while len(bytes) > self.available() and not self.err:
            bytes_written = 0
            # Large write, empty buffer. Write directly from p to avoid copy.
            if self.buffered() == 0:
                bytes_to_write = bytes[start:end]
                bytes_written = len(bytes_to_write)
                self.writer.write_bytes(bytes_to_write)

            # Write whatever we can to fill the internal buffer, then flush it to the underlying writer.
            else:
                byte_count = min(len(bytes), self.buf.capacity - self.buf.size)
                parallel_memcpy(self.buf.unsafe_ptr().offset(self.buf.size), bytes.unsafe_ptr(), byte_count)
                bytes_written += byte_count
                self.buf.size += byte_count
                self.bytes_written += byte_count
                _ = self.flush()

            total_bytes_written += bytes_written
            start = bytes_written

        if self.err:
            panic(self.err)

        # Write up to the remaining buffer capacity to the internal buffer, starting from the first available position.
        parallel_memcpy(self.buf.unsafe_ptr().offset(self.buf.size), bytes.unsafe_ptr(), len(bytes))
        self.buf.size += len(bytes)
        self.bytes_written += len(bytes)
        total_bytes_written += len(bytes)

    fn write_byte(inout self, src: UInt8) -> (Int, Error):
        """Writes a single byte to the internal buffer.

        Args:
            src: The byte to write.

        Returns:
            The number of bytes written, and an error if one occurred.
        """
        if self.err:
            return 0, self.err
        # If buffer is full, flush to the underlying writer.
        err = self.flush()
        if self.available() <= 0 and err:
            return 0, self.err

        self.buf.append(src)
        self.bytes_written += 1

        return 1, Error()

    fn write[*Ts: Writable](inout self, *args: *Ts) -> None:
        """Write data to the `Writer`."""

        @parameter
        fn write_arg[T: Writable](arg: T):
            arg.write_to(self)

        args.each[write_arg]()

    # # WriteRune writes a single Unicode code point, returning
    # # the number of bytes written and any error.
    # fn WriteRune(r rune) (size int, err error):
    #     # Compare as uint32 to correctly handle negative runes.
    #     if uint32(r) < utf8.RuneSelf:
    #         err = self.write_posriteByte(byte(r))
    #         if err != nil:
    #             return 0, err

    #         return 1, nil

    #     if self.err != nil:
    #         return 0, self.err

    #     n := self.available()
    #     if n < utf8.UTFMax:
    #         if self.flush(); self.err != nil:
    #             return 0, self.err

    #         n = self.available()
    #         if n < utf8.UTFMax:
    #             # Can only happen if buffer is silly small.
    #             return self.write_posriteString(string(r))

    #     size = utf8.EncodeRune(self.as_bytes()[self.bytes_written:], r)
    #     self.bytes_written += size
    #     return size, nil

    fn write_string(inout self, src: String) -> None:
        """Writes a string to the internal buffer.
        It returns the number of bytes written.
        If the count is less than `len(src)`, it also returns an error explaining
        why the write is short.

        Args:
            src: The string to write.
        """
        return self.write_bytes(src.as_bytes())

    fn read_from[R: io.Reader](inout self, inout reader: R) -> (Int, Error):
        """If there is buffered data and an underlying `read_from`, this fills
        the buffer and writes it before calling `read_from`.

        Args:
            reader: The reader to read from.

        Returns:
            The number of bytes read.
        """
        if self.err:
            return 0, self.err

        bytes_read = 0
        total_bytes_written = 0
        err = Error()
        while True:
            if self.available() == 0:
                err = self.flush()
                if err:
                    return total_bytes_written, err

            nr = 0
            while nr < MAX_CONSECUTIVE_EMPTY_READS:
                # Read into remaining unused space in the buffer.
                buf = self.buf.unsafe_ptr().offset(self.buf.size)
                bytes_read, err = reader._read(buf, self.buf.capacity - self.buf.size)
                self.buf.size += bytes_read

                if bytes_read != 0 or err:
                    break
                nr += 1

            if nr == MAX_CONSECUTIVE_EMPTY_READS:
                return bytes_read, Error(io.ERR_NO_PROGRESS)

            self.bytes_written += bytes_read
            total_bytes_written += bytes_read
            if err:
                break

        if err and str(err) == str(io.EOF):
            # If we filled the buffer exactly, flush preemptively.
            if self.available() == 0:
                err = self.flush()
            else:
                err = Error()

        return total_bytes_written, Error()
