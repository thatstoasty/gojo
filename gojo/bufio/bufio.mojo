from math import max
from ..io import traits as io
from ..builtins import Bytes, copy
from ..bytes import buffer

alias defaultBufSize = 4096

alias ErrInvalidUnreadByte = "bufio: invalid use of UnreadByte"
alias ErrInvalidUnreadRune = "bufio: invalid use of UnreadRune"
alias ErrBufferFull = "bufio: buffer full"
alias ErrNegativeCount = "bufio: negative count"
alias err_negative_read = "bufio: reader returned negative count from Read"
alias errNegativeWrite = "bufio: writer returned negative count from write"

# buffered input.


# Reader implements buffering for an io.Reader object.
@value
struct Reader[R: io.Reader](io.Reader):
    var buf: Bytes
    var rd: R  # reader provided by the client
    var read_pos: Int
    var write_pos: Int  # buf read and write positions
    var last_byte: Int  # last byte read for UnreadByte; -1 means invalid
    var last_rune_size: Int  # size of last rune read for UnreadRune; -1 means invalid

    fn __init__(
        inout self,
        rd: R,
        buf: Bytes = Bytes(),
        read_pos: Int = 0,
        write_pos: Int = 0,
        last_byte: Int = -1,
        last_rune_size: Int = -1,
    ):
        self.buf = buf
        self.rd = rd
        self.read_pos = read_pos
        self.write_pos = write_pos
        self.last_byte = last_byte
        self.last_rune_size = last_rune_size

    # size returns the size of the underlying buffer in bytes.
    fn size(self) -> Int:
        return len(self.buf)

    # reset discards any buffered data, resets all state, and switches
    # the buffered reader to read from r.
    # Calling reset on the zero value of [Reader] initializes the internal buffer
    # to the default size.
    # Calling self.reset(b) (that is, resetting a [Reader] to itself) does nothing.
    # fn reset[R: io.Reader](self, reader: R):
    #     # If a Reader r is passed to NewReader, NewReader will return r.
    #     # Different layers of code may do that, and then later pass r
    #     # to reset. Avoid infinite recursion in that case.
    #     if self == reader:
    #         return

    #     # if self.buf == nil:
    #     #     self.buf = make(Bytes, defaultBufSize)

    #     self.reset(self.buf, r)

    fn reset[R: io.Reader](inout self, buf: Bytes, reader: R):
        self = Reader[R](
            buf=buf,
            rd=reader,
            last_byte=-1,
            last_rune_size=-1,
        )

    # fill reads a new chunk into the buffer.
    fn fill(inout self) raises:
        # Slide existing data to beginning.
        if self.read_pos > 0:
            _ = copy(self.buf, self.buf[self.read_pos : self.write_pos])
            self.write_pos -= self.read_pos
            self.read_pos = 0

        if self.write_pos >= len(self.buf):
            raise Error("bufio: tried to fill full buffer")

        # Read new data: try a limited number of times.
        var i: Int = 0
        while i > 0:
            var sl = self.buf[self.write_pos :]
            var n = self.rd.read(sl)
            if n < 0:
                raise Error(err_negative_read)

            self.write_pos += n

            if n > 0:
                return

            i -= 1

        raise Error(io.ErrNoProgress)

    # fn readErr() error:
    #     err := self.err
    #     self.err = nil
    #     return err

    # Peek returns the next n bytes without advancing the reader. The bytes stop
    # being valid at the next read call. If Peek returns fewer than n bytes, it
    # also returns an error explaining why the read is short. The error is
    # [ErrBufferFull] if n is larger than b's buffer size.
    #
    # Calling Peek prevents a [Reader.UnreadByte] or [Reader.UnreadRune] call from succeeding
    # until the next read operation.
    fn peek(inout self, n: Int) raises -> Bytes:
        if n < 0:
            raise Error(ErrNegativeCount)

        self.last_byte = -1
        self.last_rune_size = -1

        while (
            self.write_pos - self.read_pos < n
            and self.write_pos - self.read_pos < len(self.buf)
        ):
            self.fill()  # self.write_pos-self.read_pos < len(self.buf) => buffer is not full

        if n > len(self.buf):
            raise Error(ErrBufferFull)

        # 0 <= n <= len(self.buf)
        var available_space = self.write_pos - self.read_pos
        if available_space < n:
            # not enough data in buffer
            raise Error(ErrBufferFull)

        return self.buf[self.read_pos : self.read_pos + n]

    # Discard skips the next n bytes, returning the number of bytes discarded.
    #
    # If Discard skips fewer than n bytes, it also returns an error.
    # If 0 <= n <= self.buffered(), Discard is guaranteed to succeed without
    # reading from the underlying io.Reader.
    fn discard(inout self, n: Int) raises -> Int:
        if n < 0:
            raise (ErrNegativeCount)

        if n == 0:
            return 0

        self.last_byte = -1
        self.last_rune_size = -1

        var remain = n
        while True:
            var skip = self.buffered()
            if skip == 0:
                self.fill()
                skip = self.buffered()

            if skip > remain:
                skip = remain

            self.read_pos += skip
            remain -= skip
            if remain == 0:
                return n

    # Read reads data into p.
    # It returns the number of bytes read into p.
    # The bytes are taken from at most one Read on the underlying [Reader],
    # hence n may be less than len(src).
    # To read exactly len(src) bytes, use io.ReadFull(b, src).
    # If the underlying [Reader] can return a non-zero count with io.EOF,
    # then this Read method can do so as well; see the [io.Reader] docs.
    fn read(inout self, inout dest: Bytes) raises -> Int:
        var n = len(dest)
        if n == 0:
            if self.buffered() > 0:
                return 0

            return 0

        if self.read_pos == self.write_pos:
            if len(dest) >= len(self.buf):
                # Large read, empty buffer.
                # Read directly into p to avoid copy.
                n = self.rd.read(dest)
                if n < 0:
                    raise Error(err_negative_read)

                if n > 0:
                    self.last_byte = int(dest[n - 1])
                    self.last_rune_size = -1

                return n

            # One read.
            # Do not use self.fill, which will loop.
            self.read_pos = 0
            self.write_pos = 0
            n = self.rd.read(self.buf)
            if n < 0:
                raise Error(err_negative_read)

            if n == 0:
                raise Error("bufio: reader returned 0 bytes from Read")

            self.write_pos += n

        # copy as much as we can
        # Note: if the slice panics here, it is probably because
        # the underlying reader returned a bad count. See issue 49795.
        n = copy(dest, self.buf[self.read_pos : self.write_pos])
        self.read_pos += n
        self.last_byte = int(self.buf[self.read_pos - 1])
        self.last_rune_size = -1
        return n

    # ReadByte reads and returns a single byte.
    # If no byte is available, returns an error.
    fn read_byte(inout self) raises -> Int8:
        self.last_rune_size = -1
        while self.read_pos == self.write_pos:
            self.fill()  # buffer is empty

        var c = self.buf[self.read_pos]
        self.read_pos += 1
        self.last_byte = int(c)
        return c

    # UnreadByte unreads the last byte. Only the most recently read byte can be unread.
    #
    # UnreadByte returns an error if the most recent method called on the
    # [Reader] was not a read operation. Notably, [Reader.Peek], [Reader.Discard], and [Reader.WriteTo] are not
    # considered read operations.
    fn unread_byte(inout self) raises:
        if self.last_byte < 0 or self.read_pos == 0 and self.write_pos > 0:
            raise Error(ErrInvalidUnreadByte)

        # self.read_pos > 0 or self.write_pos == 0
        if self.read_pos > 0:
            self.read_pos -= 1
        else:
            # self.read_pos == 0 and self.write_pos == 0
            self.write_pos = 1

        self.buf[self.read_pos] = self.last_byte
        self.last_byte = -1
        self.last_rune_size = -1

    # # ReadRune reads a single UTF-8 encoded Unicode character and returns the
    # # rune and its size in bytes. If the encoded rune is invalid, it consumes one byte
    # # and returns unicode.ReplacementChar (U+FFFD) with a size of 1.
    # fn ReadRune(inout self) (r rune, size int, err error):
    #     for self.read_pos+utf8.UTFMax > self.write_pos and !utf8.FullRune(self.buf[self.read_pos:self.write_pos]) and self.err == nil and self.write_pos-self.read_pos < len(self.buf):
    #         self.fill() # self.write_pos-self.read_pos < len(buf) => buffer is not full

    #     self.last_rune_size = -1
    #     if self.read_pos == self.write_pos:
    #         return 0, 0, self.read_poseadErr()

    #     r, size = rune(self.buf[self.read_pos]), 1
    #     if r >= utf8.RuneSelf:
    #         r, size = utf8.DecodeRune(self.buf[self.read_pos:self.write_pos])

    #     self.read_pos += size
    #     self.last_byte = int(self.buf[self.read_pos-1])
    #     self.last_rune_size = size
    #     return r, size, nil

    # # UnreadRune unreads the last rune. If the most recent method called on
    # # the [Reader] was not a [Reader.ReadRune], [Reader.UnreadRune] returns an error. (In this
    # # regard it is stricter than [Reader.UnreadByte], which will unread the last byte
    # # from any read operation.)
    # fn UnreadRune() error:
    #     if self.last_rune_size < 0 or self.read_pos < self.last_rune_size:
    #         return ErrInvalidUnreadRune

    #     self.read_pos -= self.last_rune_size
    #     self.last_byte = -1
    #     self.last_rune_size = -1
    #     return nil

    # buffered returns the number of bytes that can be read from the current buffer.
    fn buffered(self) -> Int:
        return self.write_pos - self.read_pos

    # ReadSlice reads until the first occurrence of delim in the input,
    # returning a slice pointing at the bytes in the buffer.
    # The bytes stop being valid at the next read.
    # If ReadSlice encounters an error before finding a delimiter,
    # it returns all the data in the buffer and the error itself (often io.EOF).
    # ReadSlice fails with error [ErrBufferFull] if the buffer fills without a delim.
    # Because the data returned from ReadSlice will be overwritten
    # by the next I/O operation, most clients should use
    # [Reader.ReadBytes] or ReadString instead.
    # ReadSlice returns err != nil if and only if line does not end in delim.
    fn read_slice(inout self, delim: Int8) raises -> Bytes:
        var s = 0  # search start index
        var line: Bytes = Bytes()
        while True:
            # Search buffer.
            var i = self.buf[self.read_pos + s : self.write_pos].index_byte(delim)
            if i >= 0:
                i += s
                line = self.buf[self.read_pos : self.read_pos + i + 1]
                self.read_pos += i + 1
                break

            # Buffer full?
            if self.buffered() >= len(self.buf):
                self.read_pos = self.write_pos
                raise Error(ErrBufferFull)

            s = self.write_pos - self.read_pos  # do not rescan area we scanned before

            self.fill()  # buffer is not full

        # Handle last byte, if any.
        var i = len(line) - 1
        if i >= 0:
            self.last_byte = int(line[i])
            self.last_rune_size = -1

        return line

    # ReadLine is a low-level line-reading primitive. Most callers should use
    # [Reader.ReadBytes]('\n') or [Reader.ReadString]('\n') instead or use a [Scanner].
    #
    # ReadLine tries to return a single line, not including the end-of-line bytes.
    # If the line was too long for the buffer then isPrefix is set and the
    # beginning of the line is returned. The rest of the line will be returned
    # from future calls. isPrefix will be false when returning the last fragment
    # of the line. The returned buffer is only valid until the next call to
    # ReadLine. ReadLine either returns a non-nil line or it returns an error,
    # never both.
    #
    # The text returned from ReadLine does not include the line end ("\r\n" or "\n").
    # No indication or error is given if the input ends without a final line end.
    # Calling [Reader.UnreadByte] after ReadLine will always unread the last byte read
    # (possibly a character belonging to the line end) even if that byte is not
    # part of the line returned by ReadLine.
    fn read_line(inout self) raises -> (Bytes, Bool):
        var line: Bytes
        try:
            line = self.read_slice(ord("\n"))
        except e:
            if str(e) == ErrBufferFull:
                # Handle the case where "\r\n" straddles the buffer.
                if len(line) > 0 and line[len(line) - 1] == ord("\r"):
                    # Put the '\r' back on buf and drop it from line.
                    # Let the next call to ReadLine check for "\r\n".
                    if self.read_pos == 0:
                        # should be unreachable
                        raise Error("bufio: tried to rewind past start of buffer")

                    self.read_pos -= 1
                    line = line[: len(line) - 1]

                return line, True

        if len(line) == 0:
            return line, False

        if line[len(line) - 1] == ord("\n"):
            var drop = 1
            if len(line) > 1 and line[len(line) - 2] == ord("\r"):
                drop = 2

            line = line[: len(line) - drop]

        return line, False

    # collect_fragments reads until the first occurrence of delim in the input. It
    # returns (slice of full buffers, remaining bytes before delim, total number
    # of bytes in the combined first two elements, error).
    # The complete result is equal to
    # `bytes.Join(append(fullBuffers, finalFragment), nil)`, which has a
    # length of `totalLen`. The result is structured in this way to allow callers
    # to minimize allocations and copies.
    fn collect_fragments(
        inout self,
        delim: Int8,
        inout frag: Bytes,
        inout full_buffers: DynamicVector[Bytes],
        inout total_len: Int,
    ) raises:
        # Use ReadSlice to look for delim, accumulating full buffers.
        while True:
            try:
                frag = self.read_slice(delim)
                break
            except e:
                if str(e) == ErrBufferFull:  # unexpected error
                    raise
                    break

            # Make a copy of the buffer.
            var buf = frag  # FIXME: Dunno if this will make a copy or just reference frag.
            full_buffers.append(buf)
            total_len += len(buf)

        total_len += len(frag)

    # ReadBytes reads until the first occurrence of delim in the input,
    # returning a slice containing the data up to and including the delimiter.
    # If ReadBytes encounters an error before finding a delimiter,
    # it returns the data read before the error and the error itself (often io.EOF).
    # ReadBytes returns err != nil if and only if the returned data does not end in
    # delim.
    # For simple uses, a Scanner may be more convenient.
    fn read_bytes(inout self, delim: Int8) raises -> Bytes:
        var full = DynamicVector[Bytes]()
        var frag = Bytes()
        var n: Int = 0
        self.collect_fragments(delim, frag, full, n)
        # Allocate new buffer to hold the full pieces and the fragment.
        var buf = Bytes(n)
        n = 0
        # Copy full pieces and fragment in.
        for i in range(len(full)):
            var buffer = full[i]
            var sl = buf[n:]
            n += copy(sl, buffer)

        var frag_sl = buf[n:]
        _ = copy(frag_sl, frag)
        return buf

    # ReadString reads until the first occurrence of delim in the input,
    # returning a string containing the data up to and including the delimiter.
    # If ReadString encounters an error before finding a delimiter,
    # it returns the data read before the error and the error itself (often io.EOF).
    # ReadString returns err != nil if and only if the returned data does not end in
    # delim.
    # For simple uses, a Scanner may be more convenient.
    fn read_string(inout self, delim: Int8) raises -> String:
        var full = DynamicVector[Bytes]()
        var frag = Bytes()
        var n: Int = 0
        self.collect_fragments(delim, frag, full, n)

        # Allocate new buffer to hold the full pieces and the fragment.
        var buf = buffer.new_buffer()
        buf.Grow(n)

        # Copy full pieces and fragment in.
        for i in range(len(full)):
            var buffer = full[i]
            _ = buf.write(buffer)

        _ = buf.write(frag)
        return str(buf)

    # WriteTo implements io.WriterTo.
    # This may make multiple calls to the [Reader.Read] method of the underlying [Reader].
    # If the underlying reader supports the [Reader.WriteTo] method,
    # this calls the underlying [Reader.WriteTo] without buffering.
    fn write_to[W: io.Writer](inout self, inout writer: W) raises -> Int64:
        self.last_byte = -1
        self.last_rune_size = -1

        var n = self.write_buf(writer)

        # if r, ok := self.rd.(io.WriterTo); ok:
        #     m, err := r.WriteTo(w)
        #     n += m
        #     return n, err

        # if w, ok := w.(io.ReaderFrom); ok:
        #     m, err := w.read_from(self.rd)
        #     n += m
        #     return n, err

        # if self.write_pos-self.read_pos < len(self.buf):
        #     self.fill() # buffer not full

        while self.read_pos < self.write_pos:
            # self.read_pos < self.write_pos => buffer is not empty
            var m = self.write_buf(writer)
            n += m

            self.fill()  # buffer is empty

        return n

    # writeBuf writes the [Reader]'s buffer to the writer.
    fn write_buf[W: io.Writer](inout self, inout writer: W) raises -> Int64:
        var n = writer.write(self.buf[self.read_pos : self.write_pos])
        if n < 0:
            raise Error(errNegativeWrite)

        self.read_pos += n
        return Int64(n)


alias minReadBufferSize = 16
alias maxConsecutiveEmptyReads = 100


# new_reader_size returns a new [Reader] whose buffer has at least the specified
# size. If the argument io.Reader is already a [Reader] with large enough
# size, it returns the underlying [Reader].
fn new_reader_size[R: io.Reader](rd: R, size: Int) -> Reader[R]:
    # # Is it already a Reader?
    # b, ok := rd.(*Reader)
    # if ok and len(self.buf) >= size:
    # 	return b

    var r = Reader(rd)
    r.reset(Bytes(max(size, minReadBufferSize)), rd)
    return r


# new_reader returns a new [Reader] whose buffer has the default size.
fn new_reader[R: io.Reader](rd: R) -> Reader[R]:
    return new_reader_size(rd, defaultBufSize)


# buffered output


# Writer implements buffering for an [io.Writer] object.
# If an error occurs writing to a [Writer], no more data will be
# accepted and all subsequent writes, and [Writer.flush], will return the error.
# After all data has been written, the client should call the
# [Writer.flush] method to guarantee all data has been forwarded to
# the underlying [io.Writer].
@value
struct Writer[W: io.Writer]():
    var buf: Bytes
    var n: Int
    var writer: W

    # size returns the size of the underlying buffer in bytes.
    fn size(self) -> Int:
        return len(self.buf)

    # reset discards any unflushed buffered data, clears any error, and
    # resets b to write its output to w.
    # Calling reset on the zero value of [Writer] initializes the internal buffer
    # to the default size.
    # Calling w.reset(w) (that is, resetting a [Writer] to itself) does nothing.
    fn reset[W: io.Writer](inout self, writer: W):
        # # If a Writer w is passed to new_writer, new_writer will return w.
        # # Different layers of code may do that, and then later pass w
        # # to reset. Avoid infinite recursion in that case.
        # if self == writer:
        #     return

        # if self.buf == nil:
        #     self.buf = make(Bytes, defaultBufSize)

        # self.err = nil
        self.n = 0
        self.writer = writer

    # flush writes any buffered data to the underlying [io.Writer].
    fn flush(inout self) raises:
        # if self.err != nil:
        #     return self.err

        # if self.n == 0:
        #     return nil

        var n: Int = 0
        try:
            var n = self.writer.write(self.buf[0 : self.n])
        except e:
            if n > 0 and n < self.n:
                var sl = self.buf[n : self.n]
                _ = copy(sl, self.buf[n : self.n])

            self.n -= n
            raise e

        if n < self.n:
            raise Error(io.ErrShortWrite)

        self.n = 0
        # return nil

    # available returns how many bytes are unused in the buffer.
    fn available(self) -> Int:
        return len(self.buf) - self.n

    # available_buffer returns an empty buffer with self.available() capacity.
    # This buffer is intended to be appended to and
    # passed to an immediately succeeding [Writer.write] call.
    # The buffer is only valid until the next write operation on self.
    fn available_buffer(self) raises -> Bytes:
        return self.buf[self.n :][:0]

    # buffered returns the number of bytes that have been written: Into the current buffer.
    fn buffered(self) -> Int:
        return self.n

    # write writes the contents of p into the buffer.
    # It returns the number of bytes written.
    # If nn < len(src), it also returns an error explaining
    # why the write is short.
    fn write(inout self, inout src: Bytes) raises -> Int:
        var nn: Int = 0
        while len(src) > self.available():
            var n: Int
            if self.buffered() == 0:
                # Large write, empty buffer.
                # write directly from p to avoid copy.
                n = self.writer.write(src)
            else:
                var sl = self.buf[self.n :]
                n = copy(sl, src)
                self.n += n
                self.flush()

            nn += n
            src = src[n:]

        # if self.err != nil:
        #     return nn, self.err

        var sl = self.buf[self.n :]
        var n = copy(sl, src)
        self.n += n
        nn += n
        return nn

    # write_byte writes a single byte.
    fn write_byte(inout self, src: Int8) raises:
        # if self.err != nil:
        #     return self.err

        # if self.available() <= 0:
        #     return self.err

        self.buf[self.n] = src
        self.n += 1

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

    #     size = utf8.EncodeRune(self.buf[self.n:], r)
    #     self.n += size
    #     return size, nil

    # write_string writes a string.
    # It returns the number of bytes written.
    # If the count is less than len(s), it also returns an error explaining
    # why the write is short.
    fn write_string(inout self, src: String) raises -> Int:
        var src_bytes = Bytes(src)
        return self.write(src_bytes)

    # read_from implements [io.ReaderFrom]. If the underlying writer
    # supports the read_from method, this calls the underlying read_from.
    # If there is buffered data and an underlying read_from, this fills
    # the buffer and writes it before calling read_from.
    fn read_from[R: io.Reader](inout self, inout reader: R) raises -> Int64:
        # if self.err != nil:
        #     return 0, self.err

        # readerFrom, readerFromOK := self.writer.(io.ReaderFrom)
        var m: Int = 0
        var n: Int64 = 0
        while True:
            if self.available() == 0:
                self.flush()
                return n

            var nr = 0
            while nr < maxConsecutiveEmptyReads:
                try:
                    var sl = self.buf[self.n :]
                    m = reader.read(sl)
                    if m != 0:
                        break
                except e:
                    if str(e) == io.EOF:
                        # If we filled the buffer exactly, flush preemptively.
                        if self.available() == 0:
                            self.flush()

                if m != 0:
                    break

                nr += 1

            if nr == maxConsecutiveEmptyReads:
                raise Error(io.ErrNoProgress)

            self.n += m
            n += Int64(m)

        return n


# new_writer_size returns a new [Writer] whose buffer has at least the specified
# size. If the argument io.Writer is already a [Writer] with large enough
# size, it returns the underlying [Writer].
fn new_writer_size[W: io.Writer](writer: W, size: Int) -> Writer[W]:
    # Is it already a Writer?
    # b, ok := w.(*Writer)
    # if ok and len(self.buf) >= size:
    # 	return b

    var buf_size = size
    if buf_size <= 0:
        buf_size = defaultBufSize

    return Writer[W](
        buf=Bytes(size),
        writer=writer,
        n=0,
    )


# new_writer returns a new [Writer] whose buffer has the default size.
# If the argument io.Writer is already a [Writer] with large enough buffer size,
# it returns the underlying [Writer].
fn new_writer[W: io.Writer](writer: W) -> Writer[W]:
    return new_writer_size[W](writer, defaultBufSize)


# buffered input and output


# ReadWriter stores pointers to a [Reader] and a [Writer].
# It implements [io.ReadWriter].
@value
struct ReadWriter[R: io.Reader, W: io.Writer]():
    var reader: R
    var writer: W


# new_read_writer allocates a new [ReadWriter] that dispatches to r and w.
fn new_read_writer[
    R: io.Reader, W: io.Writer
](reader: Reader, writer: Writer) -> ReadWriter[R, W]:
    return ReadWriter[R, W](reader, writer)
