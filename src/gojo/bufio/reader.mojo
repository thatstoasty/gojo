from memory import Span
from utils import StringSlice
from os import abort
from algorithm.memory import parallel_memcpy
from memory import UnsafePointer
import ..io
from ..bytes import index_byte, Buffer
import ..strings
import ..bytes


fn copy[
    T: CollectionElement, is_trivial: Bool
](mut target: List[T, is_trivial], source: List[T, is_trivial], start: Int = 0) -> Int:
    """Copies the contents of source into target at the same index.

    Parameters:
        T: The type of elements in the list.
        is_trivial: A boolean indicating if the type is trivial.

    Args:
        target: The buffer to copy into.
        source: The buffer to copy from.
        start: The index to start copying into.

    Returns:
        The number of bytes copied.
    """
    count = 0

    for i in range(len(source)):
        if i + start > len(target):
            target[i + start] = source[i]
        else:
            target.append(source[i])
        count += 1

    return count


struct Reader[R: io.Reader, //](Sized, io.Reader, io.ByteReader, io.ByteScanner):
    """Implements buffering for an io.Reader object.

    Parameters:
        R: The type of reader to buffer.

    Examples:
    ```mojo
    import gojo.bytes
    import gojo.bufio
    buf = bytes.Buffer(capacity=16)
    _ = buf.write("Hello, World!")
    reader = bufio.Reader(buf^)

    dest = List[Byte, True](capacity=16)
    _ = reader.read(dest)
    dest.append(0)
    print(String(dest))  # Output: Hello, World!
    ```
    """

    var buf: List[Byte, True]
    """Internal buffer."""
    var reader: R
    """Reader provided by the client."""
    var read_pos: Int
    """Buffer read position."""
    var write_pos: Int
    """Buffer write position."""
    var last_byte: Byte
    """Last byte read for unread_byte; -1 means invalid."""
    var err: Error
    """Error encountered during reading."""

    fn __init__(
        out self,
        owned reader: R,
        *,
        capacity: Int = io.BUFFER_SIZE,
    ):
        """Initializes a new buffered reader with the provided reader and buffer capacity.

        Args:
            reader: The reader to buffer.
            capacity: The initial buffer capacity.
        """
        self.buf = List[Byte, True](capacity=capacity)
        self.reader = reader^
        self.read_pos = 0
        self.write_pos = 0
        self.last_byte = -1
        self.err = Error()

    fn __moveinit__(out self, owned existing: Self):
        """Initializes a new buffered reader by moving the internal buffer and reader from an existing buffered reader.

        Args:
            existing: The existing buffered reader to move from.
        """
        self.buf = existing.buf^
        self.reader = existing.reader^
        self.read_pos = existing.read_pos
        self.write_pos = existing.write_pos
        self.last_byte = existing.last_byte
        self.err = existing.err^

    fn __len__(self) -> Int:
        """Returns the size of the underlying buffer in bytes.

        Returns:
            The size of the underlying buffer in bytes.
        """
        return len(self.buf)

    fn as_bytes(ref self) -> Span[Byte, __origin_of(self.buf)]:
        """Returns the internal data as a Span[Byte].

        Returns:
            A reference to the bytes in the internal buffer.
        """
        return Span[Byte, __origin_of(self.buf)](ptr=self.buf.unsafe_ptr(), length=self.buf.size)

    fn reset(mut self, owned reader: R) -> None:
        """Discards any buffered data, resets all state, and switches
        the buffered reader to read from `reader`. Calling reset on the `Reader` returns the internal buffer to the default size.

        Args:
            reader: The reader to buffer.
        """
        self = Reader(reader^)

    fn fill(mut self) -> None:
        """Reads a new chunk into the internal buffer from the reader."""
        # Slide existing data to beginning.
        if self.read_pos > 0:
            data_to_slide = self.as_bytes()[self.read_pos : self.write_pos]
            for i in range(len(data_to_slide)):
                self.buf[i] = data_to_slide[i]

            self.write_pos -= self.read_pos
            self.read_pos = 0

        # Compares to the capacity of the internal buffer.
        # IE. b = List[Byte, True](capacity=4096), then trying to write at b[4096] and onwards will fail.
        if self.write_pos >= self.buf.capacity:
            abort("bufio.Reader: tried to fill full buffer")

        # Read new data: try a limited number of times.
        i = MAX_CONSECUTIVE_EMPTY_READS
        while i > 0:
            try:
                bytes_read = self.reader.read(self.buf)
                if bytes_read < 0:
                    abort(ERR_NEGATIVE_READ)
                if bytes_read > 0:
                    return
            except e:
                self.err = e
                return
            finally:
                self.buf.size += bytes_read
                self.write_pos += bytes_read

            i -= 1

        self.err = Error(io.ERR_NO_PROGRESS)

    fn read_error(mut self) -> Error:
        """Returns the error encountered during reading.

        Returns:
            The error encountered during reading.
        """
        if not self.err:
            return Error()

        err = self.err
        self.err = Error()
        return err

    fn peek(mut self, number_of_bytes: Int) raises -> Span[Byte, __origin_of(self.buf)]:
        """Returns the next `number_of_bytes` bytes without advancing the reader.
        Calling `peek` prevents a `Reader.unread_byte` call from succeeding
        until the next read operation.

        Args:
            number_of_bytes: The number of bytes to peek.

        Raises:
            `ERR_NEGATIVE_COUNT`: If `number_of_bytes` is negative.
            `ERR_BUFFER_FULL`: If `number_of_bytes` is larger than the internal buffer's capacity.

        Returns:
            A reference to the bytes in the internal buffer.
        """
        if number_of_bytes < 0:
            raise Error(ERR_NEGATIVE_COUNT)

        self.last_byte = -1
        while self.write_pos - self.read_pos < number_of_bytes and self.write_pos - self.read_pos < self.buf.capacity:
            self.fill()  # self.write_pos-self.read_pos < self.capacity => buffer is not full

        if number_of_bytes > len(self.buf) or self.read_pos + number_of_bytes > len(self.buf):
            raise Error(ERR_BUFFER_FULL)

        # 0 <= n <= self.buf.size
        available_space = self.write_pos - self.read_pos
        if available_space < number_of_bytes:
            # not enough data in buffer
            err = self.read_error()
            if not err:
                raise Error(ERR_BUFFER_FULL)

        return self.as_bytes()[self.read_pos : self.read_pos + number_of_bytes]

    fn discard(mut self, number_of_bytes: Int) raises -> Int:
        """Skips the next `number_of_bytes` bytes.

        If fewer than `number_of_bytes` bytes are skipped, `discard` returns an error.
        If 0 <= `number_of_bytes` <= `self.buffered()`, `discard` is guaranteed to succeed without
        reading from the underlying `io.Reader`.

        Args:
            number_of_bytes: The number of bytes to skip.

        Returns:
            The number of bytes skipped, and an error if one occurred.

        Raises:
            `ERR_NEGATIVE_COUNT`: If `number_of_bytes` is negative.
        """
        if number_of_bytes < 0:
            raise Error(ERR_NEGATIVE_COUNT)

        if number_of_bytes == 0:
            return 0

        self.last_byte = -1
        remain = number_of_bytes
        while True:
            skip = self.buffered()
            if skip == 0:
                self.fill()
                skip = self.buffered()

            if skip > remain:
                skip = remain

            self.read_pos += skip
            remain -= skip
            if remain == 0:
                return number_of_bytes

    fn _read(mut self, dest: UnsafePointer[Byte], capacity: Int) raises -> Int:
        """Reads data into `dest`.

        The bytes are taken from at most one `read` on the underlying `io.Reader`,
        hence n may be less than `len(src`).

        To read exactly `len(src)` bytes, use `io.read_full(b, src)`.
        If the underlying `io.Reader` can return a non-zero count with `io.EOF`,
        then this `read` method can do so as well; see the `io.Reader` docs.

        Args:
            dest: The buffer to read data into.
            capacity: The capacity of the destination buffer.

        Returns:
            The number of bytes read into dest.

        Raises:
            Error: If an error occurs while reading data.
        """
        if capacity == 0:
            if self.buffered() > 0:
                return 0
            err = self.read_error()
            if err:
                raise err

        bytes_read = 0
        if self.read_pos == self.write_pos:
            if capacity >= len(self.buf):
                # Large read, empty buffer.
                # Read directly into dest to avoid copy.
                var bytes_read: Int
                try:
                    bytes_read = self.reader._read(dest, capacity)
                except e:
                    self.err = e

                if bytes_read < 0:
                    abort(ERR_NEGATIVE_READ)

                if bytes_read > 0:
                    self.last_byte = dest[bytes_read - 1]

                err = self.read_error()
                if err:
                    raise err

                return bytes_read

            # One read.
            # Do not use self.fill, which will loop.
            self.read_pos = 0
            self.write_pos = 0
            buf = self.buf.unsafe_ptr().offset(len(self.buf))
            try:
                bytes_read = self.reader._read(buf, self.buf.capacity - self.buf.size)
            except e:
                self.err = e

            if bytes_read < 0:
                abort(ERR_NEGATIVE_READ)

            if bytes_read == 0:
                err = self.read_error()
                if err:
                    raise err
                return 0

            self.write_pos += bytes_read

        # copy as much as we can
        source = self.as_bytes()[self.read_pos : self.write_pos]
        bytes_to_write = min(capacity, len(source))
        parallel_memcpy(dest, source.unsafe_ptr(), bytes_to_write)
        self.read_pos += bytes_to_write
        self.last_byte = int(self.buf[self.read_pos - 1])
        return bytes_to_write

    fn read(mut self, mut dest: List[Byte, True]) raises -> Int:
        """Reads data into `dest`.

        The bytes are taken from at most one `read` on the underlying `io.Reader`,
        hence n may be less than `len(src`).

        To read exactly `len(src)` bytes, use `io.read_full(b, src)`.
        If the underlying `io.Reader` can return a non-zero count with `io.EOF`,
        then this `read` method can do so as well; see the `io.Reader` docs.

        Args:
            dest: The buffer to read data into.

        Returns:
            The number of bytes read into dest.

        Raises:
            Error: If an error occurs while reading data.
        """
        bytes_read = self._read(dest.unsafe_ptr().offset(len(dest)), dest.capacity - dest.size)
        dest.size += bytes_read

        return bytes_read

    fn read_byte(mut self) raises -> Byte:
        """Reads and returns a single byte from the internal buffer.

        Returns:
            The byte read from the internal buffer. If no byte is available, returns an error.

        Raises:
            Error: If an error occurs while reading data.
        """
        while self.read_pos == self.write_pos:
            if self.err:
                raise self.read_error()
            self.fill()  # buffer is empty

        c = self.as_bytes()[self.read_pos]
        self.read_pos += 1
        self.last_byte = c
        return c

    fn unread_byte(mut self) raises -> None:
        """Unreads the last byte. Only the most recently read byte can be unread.

        Raises:
            Error: If the last byte read is invalid.
        """
        if self.last_byte < 0 or self.read_pos == 0 and self.write_pos > 0:
            raise Error(ERR_INVALID_UNREAD_BYTE)

        # self.read_pos > 0 or self.write_pos == 0
        if self.read_pos > 0:
            self.read_pos -= 1
        else:
            # self.read_pos == 0 and self.write_pos == 0
            self.write_pos = 1

        self.as_bytes()[self.read_pos] = self.last_byte
        self.last_byte = -1

    fn buffered(self) -> Int:
        """Returns the number of bytes that can be read from the current buffer.

        Returns:
            The number of bytes that can be read from the current buffer.
        """
        return self.write_pos - self.read_pos

    fn _search_buffer(mut self, delim: Byte) -> Span[Byte, __origin_of(self.buf)]:
        """Searches the internal buffer for the first occurrence of `delim`.

        Args:
            delim: The delimiter to search for.

        Returns:
            A reference to the bytes in the internal buffer.
        """
        start = 0  # search start index
        while True:
            # Search buffer.
            i = index_byte(self.as_bytes()[self.read_pos + start : self.write_pos], delim)
            if i >= 0:
                i += start
                line = self.as_bytes()[self.read_pos : self.read_pos + i + 1]
                self.read_pos += i + 1
                return line

            # Pending error?
            if self.err:
                line = self.as_bytes()[self.read_pos : self.write_pos]
                self.read_pos = self.write_pos
                _ = self.read_error()
                return line

            # Buffer full?
            if self.buffered() >= self.buf.capacity:
                self.read_pos = self.write_pos
                line = self.as_bytes()
                # self.err = Error(ERR_BUFFER_FULL)
                return line

            start = self.write_pos - self.read_pos  # do not rescan area we scanned before
            self.fill()  # buffer is not full

    fn read_bytes(mut self, delim: Byte) -> Span[Byte, __origin_of(self.buf)]:
        """Reads until the first occurrence of `delim` in the input, or until the buffer is full.
        If the reader encounters an error before finding a delimiter,
        it returns the data read before the error and the error itself (often `io.EOF`).
        It includes the first occurrence of the delimiter. The bytes stop being valid at the next read.

        Args:
            delim: The delimiter to search for.

        Returns:
            A reference to a Span of bytes from the internal buffer.
        """
        buffer = self._search_buffer(delim)

        # Handle last byte, if any.
        i = len(buffer) - 1
        if i >= 0:
            self.last_byte = int(buffer[i])

        return buffer

    fn read_line(mut self) -> Span[Byte, __origin_of(self.buf)]:
        """Low-level line-reading primitive. Most callers should use
        `Reader.read_bytes('\\n')` or `Reader.read_string('\\n')` instead or use a `Scanner`.

        `read_line` tries to return a single line, not including the end-of-line bytes.

        The text returned from `read_line` does not include the line end ("\\r\\n" or "\\n").
        No indication or error is given if the input ends without a final line end.
        Calling `Reader.unread_byte` after `read_line` will always unread the last byte read
        (possibly a character belonging to the line end) even if that byte is not
        part of the line returned by `read_line`.

        Returns:
            A reference to a Span of bytes from the internal buffer.
        """
        line = self.read_bytes(ord("\n"))
        if len(line) == 0:
            return line

        if line[len(line) - 1] == ord("\n"):
            drop = 1
            if len(line) > 1 and line[len(line) - 2] == ord("\r"):
                drop = 2

            line = line[: len(line) - drop]

        return line

    fn read_string(mut self, delim: Byte) raises -> String:
        """Reads until the first occurrence of `delim` in the input,
        returning a string containing the data up to and including the delimiter.

        If `read_string` encounters an error before finding a delimiter,
        it returns the data read before the error and the error itself (often `io.EOF`).
        read_string returns an error if and only if the returned data does not end in
        `delim`. For simple uses, a `Scanner` may be more convenient.

        Args:
            delim: The delimiter to search for.

        Returns:
            A copy of the data from the internal buffer as a String.
        """
        return StringSlice(unsafe_from_utf8=self.read_bytes(delim))

    fn write_buf[W: Writer, //](mut self, mut writer: W) raises -> Int:
        """Writes the `Reader`'s buffer to the `writer`.

        Parameters:
            W: The type of writer to write to.

        Args:
            writer: The writer to write to.

        Returns:
            The number of bytes written.

        Raises:
            Error: If an error occurs while writing data.
        """
        # Nothing to write
        if self.read_pos == self.write_pos:
            return 0

        # Write the buffer to the writer, if we hit EOF it's fine. That's not a failure condition.
        buf_to_write = self.as_bytes()[self.read_pos : self.write_pos]
        writer.write_bytes(buf_to_write)
        bytes_written = len(buf_to_write)

        if bytes_written < 0:
            abort(ERR_NEGATIVE_WRITE)

        self.read_pos += bytes_written
        return bytes_written
