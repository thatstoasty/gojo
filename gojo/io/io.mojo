from collections.optional import Optional
from ..builtins import cap, copy
from ..builtins._bytes import Bytes, Byte, to_bytes
from .traits import Reader, Writer, StringWriter, ErrShortBuffer, EOF


# WriteString writes the contents of the string s to w, which accepts a slice of bytes.
# If w implements [StringWriter], [StringWriter.WriteString] is invoked directly.
# Otherwise, [Writer.Write] is called exactly once.
fn write_string[T: Writer](inout w: T, s: String) raises -> Int:
    var s_buffer = to_bytes(s)
    return w.write(s_buffer)


fn write_string[T: StringWriter](inout w: T, s: String) raises -> Int:
    return w.write_string(s)


# read_at_least reads from r into buf until it has read at least min bytes.
# It returns the number of bytes copied and an error if fewer bytes were read.
# The error is EOF only if no bytes were read.
# If an EOF happens after reading fewer than min bytes,
# read_at_least returns [ErrUnexpectedEOF].
# If min is greater than the length of buf, read_at_least returns [ErrShortBuffer].
# On return, n >= min if and only if err == nil.
# If r returns an error having read at least min bytes, the error is dropped.
fn read_at_least[R: Reader](inout reader: R, dest: Bytes, min: Int) raises -> Int:
    if len(dest) < min:
        raise Error(ErrShortBuffer)

    var n: Int = 0
    while n < min:
        var sl = dest[n:]
        let nn: Int = reader.read(sl)
        n += nn

    return n


fn read_full[R: Reader](inout reader: R, dest: Bytes) raises -> Int:
    """Reads exactly len(buf) bytes from r into buf.
    It returns the number of bytes copied and an error if fewer bytes were read.
    The error is EOF only if no bytes were read.
    If an EOF happens after reading some but not all the bytes,
    read_full returns [ErrUnexpectedEOF].
    On return, n == len(buf) if and only if err == nil.
    If r returns an error having read at least len(buf) bytes, the error is dropped.
    """
    return read_at_least(reader, dest, len(dest))


# fn copy_n[W: Writer, R: Reader](dst: W, src: R, n: Int64) raises -> Int64:
#     """Copies n bytes (or until an error) from src to dst.
#     It returns the number of bytes copied and the earliest
#     error encountered while copying.
#     On return, written == n if and only if err == nil.

#     If dst implements [ReaderFrom], the copy is implemented using it.
#     """
#     let written = copy(dst, LimitReader(src, n))
#     if written == n:
#         return n

#     if written < n:
#         # src stopped early; must have been EOF.
#         raise Error(ErrUnexpectedEOF)

#     return written


# fn copy[W: Writer, R: Reader](dst: W, src: R, n: Int64) -> Int64:
#     """Copy copies from src to dst until either EOF is reached
# on src or an error occurs. It returns the number of bytes
# copied and the first error encountered while copying, if any.

# A successful Copy returns err == nil, not err == EOF.
# Because Copy is defined to read from src until EOF, it does
# not treat an EOF from Read as an error to be reported.

# If src implements [WriterTo],
# the copy is implemented by calling src.WriteTo(dst).
# Otherwise, if dst implements [ReaderFrom],
# the copy is implemented by calling dst.ReadFrom(src).
# """
#     return copy_buffer(dst, src, nil)

# # CopyBuffer is identical to Copy except that it stages through the
# # provided buffer (if one is required) rather than allocating a
# # temporary one. If buf is nil, one is allocated; otherwise if it has
# # zero length, CopyBuffer panics.
# #
# # If either src implements [WriterTo] or dst implements [ReaderFrom],
# # buf will not be used to perform the copy.
# fn CopyBuffer(dst Writer, src Reader, buf bytes) (written int64, err error) {
# 	if buf != nil and len(buf) == 0 {
# 		panic("empty buffer in CopyBuffer")
# 	}
# 	return copy_buffer(dst, src, buf)
# }


# fn copy_buffer[W: Writer, R: Reader](dst: W, src: R, buf: Bytes) raises -> Int64:
#     """Actual implementation of Copy and CopyBuffer.
#     if buf is nil, one is allocated.
#     """
#     let nr: Int
#     nr = src.read(buf)
#     while True:
#         if nr > 0:
#             let nw: Int
#             nw = dst.write(get_slice(buf, 0, nr))
#             if nw < 0 or nr < nw:
#                 nw = 0

#             let written = Int64(nw)
#             if nr != nw:
#                 raise Error(ErrShortWrite)

#     return written


# fn copy_buffer[W: Writer, R: ReaderWriteTo](dst: W, src: R, buf: Bytes) -> Int64:
#     return src.write_to(dst)


# fn copy_buffer[W: WriterReadFrom, R: Reader](dst: W, src: R, buf: Bytes) -> Int64:
#     return dst.read_from(src)

# # LimitReader returns a Reader that reads from r
# # but stops with EOF after n bytes.
# # The underlying implementation is a *LimitedReader.
# fn LimitReader(r Reader, n int64) Reader { return &LimitedReader{r, n} }

# # A LimitedReader reads from R but limits the amount of
# # data returned to just N bytes. Each call to Read
# # updates N to reflect the new amount remaining.
# # Read returns EOF when N <= 0 or when the underlying R returns EOF.
# struct LimitedReader():
# 	var R: Reader # underlying reader
# 	N int64  # max bytes remaining

# fn (l *LimitedReader) Read(p bytes) (n Int, err error) {
# 	if l.N <= 0 {
# 		return 0, EOF
# 	}
# 	if int64(len(p)) > l.N {
# 		p = p[0:l.N]
# 	}
# 	n, err = l.R.Read(p)
# 	l.N -= int64(n)
# 	return
# }

# # NewSectionReader returns a [SectionReader] that reads from r
# # starting at offset off and stops with EOF after n bytes.
# fn NewSectionReader(r ReaderAt, off int64, n int64) *SectionReader {
# 	var remaining int64
# 	const maxint64 = 1<<63 - 1
# 	if off <= maxint64-n {
# 		remaining = n + off
# 	} else {
# 		# Overflow, with no way to return error.
# 		# Assume we can read up to an offset of 1<<63 - 1.
# 		remaining = maxint64
# 	}
# 	return &SectionReader{r, off, off, remaining, n}
# }

# # SectionReader implements Read, Seek, and ReadAt on a section
# # of an underlying [ReaderAt].
# type SectionReader struct {
# 	r     ReaderAt # constant after creation
# 	base  int64    # constant after creation
# 	off   int64
# 	limit int64 # constant after creation
# 	n     int64 # constant after creation
# }

# fn (s *SectionReader) Read(p bytes) (n Int, err error) {
# 	if s.off >= s.limit {
# 		return 0, EOF
# 	}
# 	if max := s.limit - s.off; int64(len(p)) > max {
# 		p = p[0:max]
# 	}
# 	n, err = s.r.ReadAt(p, s.off)
# 	s.off += int64(n)
# 	return
# }

# alias errWhence = "Seek: invalid whence"
# alias errOffset = "Seek: invalid offset"

# fn (s *SectionReader) Seek(offset int64, whence Int) (int64, error) {
# 	switch whence {
# 	default:
# 		return 0, errWhence
# 	case seek_start:
# 		offset += s.base
# 	case seek_current:
# 		offset += s.off
# 	case seek_end:
# 		offset += s.limit
# 	}
# 	if offset < s.base {
# 		return 0, errOffset
# 	}
# 	s.off = offset
# 	return offset - s.base, nil
# }

# fn (s *SectionReader) ReadAt(p bytes, off int64) (n Int, err error) {
# 	if off < 0 or off >= s.Size() {
# 		return 0, EOF
# 	}
# 	off += s.base
# 	if max := s.limit - off; int64(len(p)) > max {
# 		p = p[0:max]
# 		n, err = s.r.ReadAt(p, off)
# 		if err == nil {
# 			err = EOF
# 		}
# 		return n, err
# 	}
# 	return s.r.ReadAt(p, off)
# }

# # Size returns the size of the section in bytes.
# fn (s *SectionReader) Size() int64 { return s.limit - s.base }

# # Outer returns the underlying [ReaderAt] and offsets for the section.
# #
# # The returned values are the same that were passed to [NewSectionReader]
# # when the [SectionReader] was created.
# fn (s *SectionReader) Outer() (r ReaderAt, off int64, n int64) {
# 	return s.r, s.base, s.n
# }

# # An OffsetWriter maps writes at offset base to offset base+off in the underlying writer.
# type OffsetWriter struct {
# 	w    WriterAt
# 	base int64 # the original offset
# 	off  int64 # the current offset
# }

# # NewOffsetWriter returns an [OffsetWriter] that writes to w
# # starting at offset off.
# fn NewOffsetWriter(w WriterAt, off int64) *OffsetWriter {
# 	return &OffsetWriter{w, off, off}
# }

# fn (o *OffsetWriter) Write(p bytes) (n Int, err error) {
# 	n, err = o.w.WriteAt(p, o.off)
# 	o.off += int64(n)
# 	return
# }

# fn (o *OffsetWriter) WriteAt(p bytes, off int64) (n Int, err error) {
# 	if off < 0 {
# 		return 0, errOffset
# 	}

# 	off += o.base
# 	return o.w.WriteAt(p, off)
# }

# fn (o *OffsetWriter) Seek(offset int64, whence Int) (int64, error) {
# 	switch whence {
# 	default:
# 		return 0, errWhence
# 	case seek_start:
# 		offset += o.base
# 	case seek_current:
# 		offset += o.off
# 	}
# 	if offset < o.base {
# 		return 0, errOffset
# 	}
# 	o.off = offset
# 	return offset - o.base, nil
# }

# # TeeReader returns a [Reader] that writes to w what it reads from r.
# # All reads from r performed through it are matched with
# # corresponding writes to w. There is no internal buffering -
# # the write must complete before the read completes.
# # Any error encountered while writing is reported as a read error.
# fn TeeReader(r Reader, w Writer) Reader {
# 	return &teeReader{r, w}
# }

# type teeReader struct {
# 	r Reader
# 	w Writer
# }

# fn (t *teeReader) Read(p bytes) (n Int, err error) {
# 	n, err = t.r.Read(p)
# 	if n > 0 {
# 		if n, err := t.w.Write(p[:n]); err != nil {
# 			return n, err
# 		}
# 	}
# 	return
# }

# # Discard is a [Writer] on which all Write calls succeed
# # without doing anything.
# var Discard Writer = discard{}

# type discard struct{}

# # discard implements ReaderFrom as an optimization so Copy to
# # io.Discard can avoid doing unnecessary work.
# var _ ReaderFrom = discard{}

# fn (discard) Write(p bytes) (Int, error) {
# 	return len(p), nil
# }

# fn (discard) WriteString(s string) (Int, error) {
# 	return len(s), nil
# }

# var blackHolePool = sync.Pool{
# 	New: fn() any {
# 		b := make(bytes, 8192)
# 		return &b
# 	},
# }

# fn (discard) ReadFrom(r Reader) (n int64, err error) {
# 	bufp := blackHolePool.Get().(*bytes)
# 	readSize := 0
# 	for {
# 		readSize, err = r.Read(*bufp)
# 		n += int64(readSize)
# 		if err != nil {
# 			blackHolePool.Put(bufp)
# 			if err == EOF {
# 				return n, nil
# 			}
# 			return
# 		}
# 	}
# }

# # NopCloser returns a [ReadCloser] with a no-op Close method wrapping
# # the provided [Reader] r.
# # If r implements [WriterTo], the returned [ReadCloser] will implement [WriterTo]
# # by forwarding calls to r.
# fn NopCloser(r Reader) ReadCloser {
# 	if _, ok := r.(WriterTo); ok {
# 		return nopCloserWriterTo{r}
# 	}
# 	return nopCloser{r}
# }

# type nopCloser struct {
# 	Reader
# }

# fn (nopCloser) Close() error { return nil }

# type nopCloserWriterTo struct {
# 	Reader
# }

# fn (nopCloserWriterTo) Close() error { return nil }

# fn (c nopCloserWriterTo) WriteTo(w Writer) (n int64, err error) {
# 	return c.Reader.(WriterTo).WriteTo(w)
# }


# ReadAll reads from r until an error or EOF and returns the data it read.
# A successful call returns err == nil, not err == EOF. Because ReadAll is
# defined to read from src until EOF, it does not treat an EOF from Read
# as an error to be reported.
fn read_all[R: Reader](inout reader: R) raises -> Bytes:
    var dest = Bytes()
    var index: Int = 0

    while True:
        try:
            index = reader.read(dest)
        except e:
            if e.__str__() == EOF:
                break
            raise

    return dest
