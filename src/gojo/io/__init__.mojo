"""`io` provides basic interfaces to I/O primitives.
Its primary job is to wrap existing implementations of such primitives,
such as those in package os, into shared public interfaces that
abstract the fntionality, plus some other related primitives.

Because these interfaces and primitives wrap lower-level operations with
various implementations, unless otherwise informed clients should not
assume they are safe for parallel execution.
seek whence values.
"""
from .io import read_at_least, read_full, read_all, BUFFER_SIZE
from .traits import (
    SEEK_START,
    SEEK_CURRENT,
    SEEK_END,
    ERR_SHORT_WRITE,
    ERR_INVALID_WRITE,
    ERR_SHORT_BUFFER,
    EOF,
    ERR_UNEXPECTED_EOF,
    ERR_NO_PROGRESS,
    Reader,
    Closer,
    Seeker,
    ReaderFrom,
    ByteReader,
    ByteScanner,
)
