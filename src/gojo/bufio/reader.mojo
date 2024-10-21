# from utils import Span
# from os import abort
# from algorithm.memory import parallel_memcpy
# from memory import UnsafePointer
# import ..io
# from ..bytes import index_byte
# from ..strings import StringBuilder


# fn copy[
#     T: CollectionElement, is_trivial: Bool
# ](inout target: List[T, is_trivial], source: List[T, is_trivial], start: Int = 0) -> Int:
#     """Copies the contents of source into target at the same index.

#     Args:
#         target: The buffer to copy into.
#         source: The buffer to copy from.
#         start: The index to start copying into.

#     Returns:
#         The number of bytes copied.
#     """
#     count = 0

#     for i in range(len(source)):
#         if i + start > len(target):
#             target[i + start] = source[i]
#         else:
#             target.append(source[i])
#         count += 1

#     return count


# struct Reader[R: io.Reader, //](Sized, io.Reader, io.ByteReader, io.ByteScanner):
#     """Implements buffering for an io.Reader object.

#     Examples:
#     ```mojo
#     import gojo.bytes
#     import gojo.bufio
#     var buf = bytes.Buffer(capacity=16)
#     _ = buf.write_string("Hello, World!")
#     var reader = bufio.Reader(buf^)

#     var dest = List[Byte, True](capacity=16)
#     _ = reader.read(dest)
#     dest.append(0)
#     print(String(dest))  # Output: Hello, World!
#     ```
#     """

#     var buf: List[Byte, True]
#     """Internal buffer."""
#     var reader: R
#     """Reader provided by the client."""
#     var read_pos: Int
#     """Buffer read position."""
#     var write_pos: Int
#     """Buffer write position."""
#     var last_byte: Int
#     """Last byte read for unread_byte; -1 means invalid."""
#     var last_rune_size: Int
#     """Size of last rune read for unread_rune; -1 means invalid."""
#     var err: Error
#     """Error encountered during reading."""

#     fn __init__(
#         inout self,
#         owned reader: R,
#         *,
#         capacity: Int = io.BUFFER_SIZE,
#     ):
#         """Initializes a new buffered reader with the provided reader and buffer capacity.

#         Args:
#             reader: The reader to buffer.
#             capacity: The initial buffer capacity.
#         """
#         self.buf = List[Byte, True](capacity=capacity)
#         self.reader = reader^
#         self.read_pos = 0
#         self.write_pos = 0
#         self.last_byte = -1
#         self.last_rune_size = -1
#         self.err = Error()

#     fn __moveinit__(inout self, owned existing: Self):
#         self.buf = existing.buf^
#         self.reader = existing.reader^
#         self.read_pos = existing.read_pos
#         self.write_pos = existing.write_pos
#         self.last_byte = existing.last_byte
#         self.last_rune_size = existing.last_rune_size
#         self.err = existing.err^

#     fn __len__(self) -> Int:
#         """Returns the size of the underlying buffer in bytes."""
#         return len(self.buf)

#     # reset discards any buffered data, resets all state, and switches
#     # the buffered reader to read from r.
#     # Calling reset on the zero value of [Reader] initializes the internal buffer
#     # to the default size.
#     # Calling self.reset(b) (that is, resetting a [Reader] to itself) does nothing.
#     # fn reset[R: io.Reader](self, reader: R):
#     #     # If a Reader r is passed to NewReader, NewReader will return r.
#     #     # Different layers of code may do that, and then later pass r
#     #     # to reset. Avoid infinite recursion in that case.
#     #     if self == reader:
#     #         return

#     #     # if self.buf == nil:
#     #     #     self.buf = make(InlineList[Byte, io.BUFFER_SIZE], io.BUFFER_SIZE)

#     #     self.reset(self.buf, r)

#     fn as_bytes(ref [_]self) -> Span[Byte, __origin_of(self)]:
#         """Returns the internal data as a Span[Byte]."""
#         return Span[Byte, __origin_of(self)](unsafe_ptr=self.buf.unsafe_ptr(), len=self.buf.size)

#     fn reset(inout self, owned reader: R) -> None:
#         """Discards any buffered data, resets all state, and switches
#         the buffered reader to read from `reader`. Calling reset on the `Reader` returns the internal buffer to the default size.

#         Args:
#             reader: The reader to buffer.
#         """
#         self = Reader(reader^)

#     fn fill(inout self) -> None:
#         """Reads a new chunk into the internal buffer from the reader."""
#         # Slide existing data to beginning.
#         if self.read_pos > 0:
#             data_to_slide = self.as_bytes()[self.read_pos : self.write_pos]
#             for i in range(len(data_to_slide)):
#                 self.buf[i] = data_to_slide[i]

#             self.write_pos -= self.read_pos
#             self.read_pos = 0

#         # Compares to the capacity of the internal buffer.
#         # IE. b = List[Byte, True](capacity=4096), then trying to write at b[4096] and onwards will fail.
#         if self.write_pos >= self.buf.capacity:
#             abort("bufio.Reader: tried to fill full buffer")

#         # Read new data: try a limited number of times.
#         i = MAX_CONSECUTIVE_EMPTY_READS
#         while i > 0:
#             dest_ptr = self.buf.unsafe_ptr().offset(self.buf.size)
#             var bytes_read: Int
#             var err: Error
#             bytes_read, err = self.reader._read(dest_ptr, self.buf.capacity - self.buf.size)
#             if bytes_read < 0:
#                 abort(ERR_NEGATIVE_READ)

#             self.buf.size += bytes_read
#             self.write_pos += bytes_read

#             if err:
#                 self.err = err
#                 return

#             if bytes_read > 0:
#                 return

#             i -= 1

#         self.err = Error(str(io.ERR_NO_PROGRESS))

#     fn read_error(inout self) -> Error:
#         """Returns the error encountered during reading."""
#         if not self.err:
#             return Error()

#         err = self.err
#         self.err = Error()
#         return err

#     fn peek(inout self, number_of_bytes: Int) -> (Span[Byte, __origin_of(self)], Error):
#         """Returns the next `number_of_bytes` bytes without advancing the reader. The bytes stop
#         being valid at the next read call. If `peek` returns fewer than `number_of_bytes` bytes, it
#         also returns an error explaining why the read is short. The error is
#         `ERR_BUFFER_FULL` if `number_of_bytes` is larger than the internal buffer's capacity.

#         Calling `peek` prevents a `Reader.unread_byte` or `Reader.unread_rune` call from succeeding
#         until the next read operation.

#         Args:
#             number_of_bytes: The number of bytes to peek.

#         Returns:
#             A reference to the bytes in the internal buffer, and an error if one occurred.
#         """
#         if number_of_bytes < 0:
#             return self.as_bytes()[0:0], Error(ERR_NEGATIVE_COUNT)

#         self.last_byte = -1
#         self.last_rune_size = -1

#         while self.write_pos - self.read_pos < number_of_bytes and self.write_pos - self.read_pos < self.buf.capacity:
#             self.fill()  # self.write_pos-self.read_pos < self.capacity => buffer is not full

#         if number_of_bytes > self.buf.size:
#             return self.as_bytes()[self.read_pos : self.write_pos], Error(ERR_BUFFER_FULL)

#         # 0 <= n <= self.buf.size
#         var err = Error()
#         var available_space = self.write_pos - self.read_pos
#         if available_space < number_of_bytes:
#             # not enough data in buffer
#             err = self.read_error()
#             if not err:
#                 err = Error(ERR_BUFFER_FULL)

#         return self.as_bytes()[self.read_pos : self.read_pos + number_of_bytes], err

#     fn discard(inout self, number_of_bytes: Int) -> (Int, Error):
#         """Skips the next `number_of_bytes` bytes.

#         If fewer than `number_of_bytes` bytes are skipped, `discard` returns an error.
#         If 0 <= `number_of_bytes` <= `self.buffered()`, `discard` is guaranteed to succeed without
#         reading from the underlying `io.Reader`.

#         Args:
#             number_of_bytes: The number of bytes to skip.

#         Returns:
#             The number of bytes skipped, and an error if one occurred.
#         """
#         if number_of_bytes < 0:
#             return 0, Error(ERR_NEGATIVE_COUNT)

#         if number_of_bytes == 0:
#             return 0, Error()

#         self.last_byte = -1
#         self.last_rune_size = -1

#         var remain = number_of_bytes
#         while True:
#             var skip = self.buffered()
#             if skip == 0:
#                 self.fill()
#                 skip = self.buffered()

#             if skip > remain:
#                 skip = remain

#             self.read_pos += skip
#             remain -= skip
#             if remain == 0:
#                 return number_of_bytes, Error()

#     fn _read(inout self, inout dest: UnsafePointer[Byte], capacity: Int) -> (Int, Error):
#         """Reads data into `dest`.

#         The bytes are taken from at most one `read` on the underlying `io.Reader`,
#         hence n may be less than `len(src`).

#         To read exactly `len(src)` bytes, use `io.read_full(b, src)`.
#         If the underlying `io.Reader` can return a non-zero count with `io.EOF`,
#         then this `read` method can do so as well; see the `io.Reader` docs.

#         Args:
#             dest: The buffer to read data into.
#             capacity: The capacity of the destination buffer.

#         Returns:
#             The number of bytes read into dest.
#         """
#         if capacity == 0:
#             if self.buffered() > 0:
#                 return 0, Error()
#             return 0, self.read_error()

#         var bytes_read: Int = 0
#         if self.read_pos == self.write_pos:
#             if capacity >= len(self.buf):
#                 # Large read, empty buffer.
#                 # Read directly into dest to avoid copy.
#                 var bytes_read: Int
#                 bytes_read, self.err = self.reader._read(dest, capacity)

#                 if bytes_read < 0:
#                     abort(ERR_NEGATIVE_READ)

#                 if bytes_read > 0:
#                     self.last_byte = int(dest[bytes_read - 1])
#                     self.last_rune_size = -1

#                 return bytes_read, self.read_error()

#             # One read.
#             # Do not use self.fill, which will loop.
#             self.read_pos = 0
#             self.write_pos = 0
#             var buf = self.buf.unsafe_ptr().offset(self.buf.size)
#             var bytes_read: Int
#             bytes_read, self.err = self.reader._read(buf, self.buf.capacity - self.buf.size)

#             if bytes_read < 0:
#                 abort(ERR_NEGATIVE_READ)

#             if bytes_read == 0:
#                 return 0, self.read_error()

#             self.write_pos += bytes_read

#         # copy as much as we can
#         var source = self.as_bytes()[self.read_pos : self.write_pos]
#         var bytes_to_write = min(capacity, len(source))
#         parallel_memcpy(dest, source.unsafe_ptr(), bytes_to_write)
#         self.read_pos += bytes_to_write
#         self.last_byte = int(self.buf[self.read_pos - 1])
#         self.last_rune_size = -1
#         return bytes_to_write, Error()

#     fn read(inout self, inout dest: List[Byte, True]) -> (Int, Error):
#         """Reads data into `dest`.

#         The bytes are taken from at most one `read` on the underlying `io.Reader`,
#         hence n may be less than `len(src`).

#         To read exactly `len(src)` bytes, use `io.read_full(b, src)`.
#         If the underlying `io.Reader` can return a non-zero count with `io.EOF`,
#         then this `read` method can do so as well; see the `io.Reader` docs.

#         Args:
#             dest: The buffer to read data into.

#         Returns:
#             The number of bytes read into dest.
#         """
#         var dest_ptr = dest.unsafe_ptr().offset(dest.size)
#         var bytes_read: Int
#         var err: Error
#         bytes_read, err = self._read(dest_ptr, dest.capacity - dest.size)
#         dest.size += bytes_read

#         return bytes_read, err

#     fn read_byte(inout self) -> (Byte, Error):
#         """Reads and returns a single byte from the internal buffer.

#         Returns:
#             The byte read from the internal buffer. If no byte is available, returns an error.
#         """
#         self.last_rune_size = -1
#         while self.read_pos == self.write_pos:
#             if self.err:
#                 return Byte(0), self.read_error()
#             self.fill()  # buffer is empty

#         var c = self.as_bytes()[self.read_pos]
#         self.read_pos += 1
#         self.last_byte = int(c)
#         return c, Error()

#     fn unread_byte(inout self) -> Error:
#         """Unreads the last byte. Only the most recently read byte can be unread.

#         Returns:
#             `unread_byte` returns an error if the most recent method called on the
#             `Reader` was not a read operation. Notably, `Reader.peek`, `Reader.discard`, and `Reader.write_to` are not
#             considered read operations.
#         """
#         if self.last_byte < 0 or self.read_pos == 0 and self.write_pos > 0:
#             return Error(ERR_INVALID_UNREAD_BYTE)

#         # self.read_pos > 0 or self.write_pos == 0
#         if self.read_pos > 0:
#             self.read_pos -= 1
#         else:
#             # self.read_pos == 0 and self.write_pos == 0
#             self.write_pos = 1

#         self.as_bytes()[self.read_pos] = self.last_byte
#         self.last_byte = -1
#         self.last_rune_size = -1
#         return Error()

#     # # read_rune reads a single UTF-8 encoded Unicode character and returns the
#     # # rune and its size in bytes. If the encoded rune is invalid, it consumes one byte
#     # # and returns unicode.ReplacementChar (U+FFFD) with a size of 1.
#     # fn read_rune(inout self) (r rune, size int, err error):
#     #     for self.read_pos+utf8.UTFMax > self.write_pos and !utf8.FullRune(self.as_bytes()[self.read_pos:self.write_pos]) and self.err == nil and self.write_pos-self.read_pos < self.buf.capacity:
#     #         self.fill() # self.write_pos-self.read_pos < len(buf) => buffer is not full

#     #     self.last_rune_size = -1
#     #     if self.read_pos == self.write_pos:
#     #         return 0, 0, self.read_poseadErr()

#     #     r, size = rune(self.as_bytes()[self.read_pos]), 1
#     #     if r >= utf8.RuneSelf:
#     #         r, size = utf8.DecodeRune(self.as_bytes()[self.read_pos:self.write_pos])

#     #     self.read_pos += size
#     #     self.last_byte = int(self.as_bytes()[self.read_pos-1])
#     #     self.last_rune_size = size
#     #     return r, size, nil

#     # # unread_rune unreads the last rune. If the most recent method called on
#     # # the [Reader] was not a [Reader.read_rune], [Reader.unread_rune] returns an error. (In this
#     # # regard it is stricter than [Reader.unread_byte], which will unread the last byte
#     # # from any read operation.)
#     # fn unread_rune() error:
#     #     if self.last_rune_size < 0 or self.read_pos < self.last_rune_size:
#     #         return ERR_INVALID_UNREAD_RUNE

#     #     self.read_pos -= self.last_rune_size
#     #     self.last_byte = -1
#     #     self.last_rune_size = -1
#     #     return nil

#     fn buffered(self) -> Int:
#         """Returns the number of bytes that can be read from the current buffer.

#         Returns:
#             The number of bytes that can be read from the current buffer.
#         """
#         return self.write_pos - self.read_pos

#     fn _search_buffer(inout self, delim: Byte) -> (Span[Byte, __origin_of(self)], Error):
#         var start = 0  # search start index
#         while True:
#             # Search buffer.
#             var i = index_byte(self.as_bytes()[self.read_pos + start : self.write_pos], delim)
#             if i >= 0:
#                 i += start
#                 line = self.as_bytes()[self.read_pos : self.read_pos + i + 1]
#                 self.read_pos += i + 1
#                 return line, Error()

#             # Pending error?
#             if self.err:
#                 line = self.as_bytes()[self.read_pos : self.write_pos]
#                 self.read_pos = self.write_pos
#                 err = self.read_error()
#                 return line, err

#             # Buffer full?
#             if self.buffered() >= self.buf.capacity:
#                 self.read_pos = self.write_pos
#                 line = self.as_bytes()
#                 err = Error(ERR_BUFFER_FULL)
#                 return line, err

#             start = self.write_pos - self.read_pos  # do not rescan area we scanned before
#             self.fill()  # buffer is not full

#     fn read_span(inout self, delim: Byte) -> (Span[Byte, __origin_of(self)], Error):
#         """Reads until the first occurrence of `delim` in the input, returning a slice pointing at the bytes in the buffer.
#         It includes the first occurrence of the delimiter. The bytes stop being valid at the next read.

#         If `read_span` encounters an error before finding a delimiter, it returns all the data in the buffer and the error itself (often `io.EOF`).
#         `read_span` fails with error `ERR_BUFFER_FULL` if the buffer fills without a `delim`.
#         Because the data returned from `read_span` will be overwritten by the next I/O operation,
#         most clients should use `Reader.read_bytes` or `Reader.read_string` instead.
#         `read_span` returns an error if and only if line does not end in delim.

#         Args:
#             delim: The delimiter to search for.

#         Returns:
#             A reference to a Span of bytes from the internal buffer.
#         """
#         var result = self._search_buffer(delim)

#         # Handle last byte, if any.
#         var i = len(result[0]) - 1
#         if i >= 0:
#             self.last_byte = int(result[0][i])
#             self.last_rune_size = -1

#         return result[0], result[1]

#     fn read_line(inout self) -> (List[Byte, True], Bool):
#         """Low-level line-reading primitive. Most callers should use
#         `Reader.read_bytes('\\n')` or `Reader.read_string]('\\n')` instead or use a `Scanner`.

#         `read_line` tries to return a single line, not including the end-of-line bytes.

#         The text returned from `read_line` does not include the line end ("\\r\\n" or "\\n").
#         No indication or error is given if the input ends without a final line end.
#         Calling `Reader.unread_byte` after `read_line` will always unread the last byte read
#         (possibly a character belonging to the line end) even if that byte is not
#         part of the line returned by `read_line`.
#         """
#         var line: Span[Byte, __origin_of(self)]
#         var err: Error
#         line, err = self.read_span(ord("\n"))

#         if err and str(err) == ERR_BUFFER_FULL:
#             # Handle the case where "\r\n" straddles the buffer.
#             if len(line) > 0 and line[len(line) - 1] == ord("\r"):
#                 # Put the '\r' back on buf and drop it from line.
#                 # Let the next call to read_line check for "\r\n".
#                 if self.read_pos == 0:
#                     # should be unreachable
#                     abort("bufio: tried to rewind past start of buffer")

#                 self.read_pos -= 1
#                 line = line[: len(line) - 1]
#             return List[Byte, True](line), True

#         if len(line) == 0:
#             return List[Byte, True](line), False

#         if line[len(line) - 1] == ord("\n"):
#             var drop = 1
#             if len(line) > 1 and line[len(line) - 2] == ord("\r"):
#                 drop = 2

#             line = line[: len(line) - drop]

#         return List[Byte, True](line), False

#     fn collect_fragments(
#         inout self, delim: Byte
#     ) -> (List[List[Byte, True]], Span[Byte, __origin_of(self)], Int, Error):
#         """Reads until the first occurrence of `delim` in the input. It
#         returns (list of full buffers, remaining bytes before `delim`, total number
#         of bytes in the combined first two elements, error).

#         Args:
#             delim: The delimiter to search for.

#         Returns:
#             List of full buffers, the remaining bytes before `delim`, the total number of bytes in the combined first two elements, and an error if one occurred.
#         """
#         # Use read_span to look for delim, accumulating full buffers.
#         var err = Error()
#         var full_buffers = List[List[Byte, True]]()
#         var total_len = 0
#         var frag: Span[Byte, __origin_of(self)]
#         while True:
#             frag, err = self.read_span(delim)
#             if not err:
#                 break

#             var read_span_error = err
#             if str(read_span_error) != ERR_BUFFER_FULL:
#                 err = read_span_error
#                 break

#             # Make a copy of the buffer Span.
#             var buf = List[Byte, True](frag)
#             full_buffers.append(buf)
#             total_len += len(buf)

#         total_len += len(frag)
#         return full_buffers, frag, total_len, err

#     fn read_bytes(inout self, delim: Byte) -> (List[Byte, True], Error):
#         """Reads until the first occurrence of `delim` in the input,
#         returning a List containing the data up to and including the delimiter.

#         If `read_bytes` encounters an error before finding a delimiter,
#         it returns the data read before the error and the error itself (often `io.EOF`).
#         `read_bytes` returns an error if and only if the returned data does not end in
#         `delim`. For simple uses, a `Scanner` may be more convenient.

#         Args:
#             delim: The delimiter to search for.

#         Returns:
#             The a copy of the bytes from the internal buffer as a list.
#         """
#         var full: List[List[Byte, True]]
#         var frag: Span[Byte, __origin_of(self)]
#         var n: Int
#         var err: Error
#         full, frag, n, err = self.collect_fragments(delim)

#         # Allocate new buffer to hold the full pieces and the fragment.
#         var buf = List[Byte, True](capacity=n)
#         n = 0

#         # copy full pieces and fragment in.
#         for i in range(len(full)):
#             n += copy(buf, full[i], n)

#         _ = copy(buf, frag, n)
#         return buf, err

#     fn read_string(inout self, delim: Byte) -> (String, Error):
#         """Reads until the first occurrence of `delim` in the input,
#         returning a string containing the data up to and including the delimiter.

#         If `read_string` encounters an error before finding a delimiter,
#         it returns the data read before the error and the error itself (often `io.EOF`).
#         read_string returns an error if and only if the returned data does not end in
#         `delim`. For simple uses, a `Scanner` may be more convenient.

#         Args:
#             delim: The delimiter to search for.

#         Returns:
#             A copy of the data from the internal buffer as a String.
#         """
#         var full: List[List[Byte, True]]
#         var frag: Span[Byte, __origin_of(self)]
#         var n: Int
#         var err: Error
#         full, frag, n, err = self.collect_fragments(delim)

#         # Allocate new buffer to hold the full pieces and the fragment.
#         var buf = StringBuilder(capacity=n)

#         # copy full pieces and fragment in.
#         for i in range(len(full)):
#             var buffer = full[i]
#             _ = buf.write_bytes(buffer)

#         _ = buf.write_bytes(frag)
#         return str(buf), err

#     fn write_to[W: io.Writer](inout self, inout writer: W) -> (Int, Error):
#         """Writes the internal buffer to the writer.
#         This may make multiple calls to the `Reader.read` method of the underlying `Reader`.

#         Args:
#             writer: The writer to write to.

#         Returns:
#             The number of bytes written.
#         """
#         self.last_byte = -1
#         self.last_rune_size = -1

#         var bytes_written: Int
#         var err: Error
#         bytes_written, err = self.write_buf(writer)
#         if err:
#             return bytes_written, err

#         # internal buffer not full, fill before writing to writer
#         if (self.write_pos - self.read_pos) < self.buf.capacity:
#             self.fill()

#         while self.read_pos < self.write_pos:
#             # self.read_pos < self.write_pos => buffer is not empty
#             var bw: Int
#             var err: Error
#             bw, err = self.write_buf(writer)
#             bytes_written += bw

#             self.fill()  # buffer is empty

#         return bytes_written, Error()

#     fn write_buf[W: Writer](inout self, inout writer: W) -> (Int, Error):
#         """Writes the `Reader`'s buffer to the `writer`.

#         Args:
#             writer: The writer to write to.

#         Returns:
#             The number of bytes written.
#         """
#         # Nothing to write
#         if self.read_pos == self.write_pos:
#             return Int(0), Error()

#         # Write the buffer to the writer, if we hit EOF it's fine. That's not a failure condition.
#         buf_to_write = self.as_bytes()[self.read_pos : self.write_pos]
#         writer.write_bytes(buf_to_write)
#         bytes_written = len(buf_to_write)

#         if bytes_written < 0:
#             abort(ERR_NEGATIVE_WRITE)

#         self.read_pos += bytes_written
#         return Int(bytes_written), Error()
