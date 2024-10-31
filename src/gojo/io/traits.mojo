from memory import UnsafePointer
from utils import Span


alias SEEK_START = 0
"""seek relative to the origin of the file."""
alias SEEK_CURRENT = 1
"""seek relative to the current offset."""
alias SEEK_END = 2
"""seek relative to the end."""

alias ERR_SHORT_WRITE = "short write"
"""A write accepted fewer bytes than requested, but failed to return an explicit error."""

alias ERR_INVALID_WRITE = "invalid write result"
"""A write returned an impossible count."""

alias ERR_SHORT_BUFFER = "short buffer"
"""A read required a longer buffer than was provided."""

alias EOF = "EOF"
"""Returned by `read` when no more input is available.
(`read` must return `EOF` itself, not an error wrapping EOF,
because callers will test for EOF using `==`)

Functions should return `EOF` only to signal a graceful end of input.
If the `EOF` occurs unexpectedly in a structured data stream,
the appropriate error is either `ERR_UNEXPECTED_EOF` or some other error
giving more detail."""

alias ERR_UNEXPECTED_EOF = "unexpected EOF"
"""EOF was encountered in the middle of reading a fixed-size block or data structure."""

alias ERR_NO_PROGRESS = "multiple read calls return no data or error"
"""Returned by some clients of a `Reader` when
many calls to read have failed to return any data or error,
usually the sign of a broken `Reader` implementation."""


trait Reader(Movable):
    """Wraps the basic `read` method.

    `read` reads up to `len(dest)` bytes into p. It returns the number of bytes
    `read` `(0 <= n <= len(dest))` and any error encountered. Even if `read`
    returns n < `len(dest)`, it may use all of p as scratch space during the call.
    If some data is available but not `len(dest)` bytes, read conventionally
    returns what is available instead of waiting for more.

    When read encounters an error or end-of-file condition after
    successfully reading n > 0 bytes, it returns the number of
    bytes read. It may return an error from the same call
    or return the error (and n == 0) from a subsequent call.
    An instance of this general case is that a Reader returning
    a non-zero number of bytes at the end of the input stream may
    return either err == `EOF` or err == Error(). The next read should
    return 0, EOF.

    Callers should always process the n > 0 bytes returned before
    considering the error err. Doing so correctly handles I/O errors
    that happen after reading some bytes and also both of the
    allowed `EOF` behaviors.

    If `len(dest) == 0`, `read` should always return n == 0. It may return an
    error if some error condition is known, such as `EOF`.

    Implementations of `read` are discouraged from returning a
    zero byte count with an empty error, except when `len(dest) == 0`.
    Callers should treat a return of 0 and an empty error as indicating that
    nothing happened; in particular it does not indicate `EOF`.

    Implementations must not retain `dest`."""

    fn read(inout self, inout dest: List[Byte, True]) raises -> Int:
        ...

    fn _read(inout self, dest: UnsafePointer[Byte], capacity: Int) raises -> Int:
        ...


trait Closer(Movable):
    """Wraps the basic `close` method.

    The behavior of `close` after the first call is undefined.
    Specific implementations may document their own behavior.
    """

    fn close(inout self) raises -> None:
        ...


trait Seeker(Movable):
    """Wraps the basic `seek` method.

    `seek` sets the offset for the next read or write to offset,
    interpreted according to whence:
    `SEEK_START` means relative to the start of the file,
    `SEEK_CURRENT` means relative to the current offset, and
    `SEEK_END]` means relative to the end
    (for example, `offset = -2` specifies the penultimate byte of the file).
    `seek` returns the new offset relative to the start of the
    file or an error, if any.

    Seeking to an offset before the start of the file is an error.
    Seeking to any positive offset may be allowed, but if the new offset exceeds
    the size of the underlying object the behavior of subsequent I/O operations
    is implementation dependent.
    """

    fn seek(inout self, offset: Int, whence: Int) raises -> Int:
        ...


trait ReaderFrom:
    """Wraps the `read_from` method.

    `read_from` reads data from `reader` until `EOF` or error.
    The return value n is the number of bytes read.
    Any error except `EOF` encountered during the read is also returned.
    """

    fn read_from[R: Reader](inout self, inout reader: R) raises -> Int:
        ...


trait ByteReader:
    """Wraps the `read_byte` method.

    `read_byte` reads and returns the next byte from the input or
    any error encountered. If `read_byte` returns an error, no input
    byte was consumed, and the returned byte value is undefined.

    `read_byte` provides an efficient trait for byte-at-time
    processing. A `Reader` that does not implement `ByteReader`
    can be wrapped using `bufio.Reader` to add this method."""

    fn read_byte(inout self) raises -> Byte:
        ...


trait ByteScanner(ByteReader):
    """Adds the `unread_byte` method to the basic `read_byte` method.

    `unread_byte` causes the next call to `read_byte` to return the last byte read.
    If the last operation was not a successful call to `read_byte`, `unread_byte` may
    return an error, unread the last byte read (or the byte prior to the
    last-unread byte), or (in implementations that support the `Seeker` trait)
    seek to one byte before the current offset."""

    fn unread_byte(inout self) raises -> None:
        ...
