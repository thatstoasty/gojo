from utils import StringSlice, Span
from memory import memcpy
from bit import count_leading_zeros
import ..io
from ..builtins import copy, panic, index_byte
from .bufio import MAX_CONSECUTIVE_EMPTY_READS


alias MAX_INT: Int = 2147483647


struct Scanner[R: io.Reader, split: SplitFunction = scan_lines, capacity: Int = io.BUFFER_SIZE]():
    """`Scanner` provides a convenient interface for reading data such as
    a file of newline-delimited lines of text. Successive calls to
    the `Scanner.scan` method will step through the 'tokens' of a file, skipping
    the bytes between the tokens. The specification of a token is
    defined by a split function of type `SplitFunction`.

    The default split function breaks the input int lines with line termination stripped.
    `Scanner.split` functions are defined in this package for scanning a file into
    lines, bytes, UTF-8-encoded runes, and space-delimited words. The
    client may instead provide a custom split function.

    Scanning stops unrecoverably at EOF, the first I/O error, or a token too
    large to fit in the `Scanner.buffer`. When a scan stops, the reader may have
    advanced arbitrarily far past the last token. Programs that need more
    control over error handling or large tokens, or must run sequential scans
    on a reader, should use `bufio.Reader` instead.
    """

    var reader: R
    """The reader provided by the client."""
    var max_token_size: Int
    """Maximum size of a token; modified by tests."""
    var token: List[UInt8, True]
    """Last token returned by split."""
    var buf: List[UInt8, True]
    """Internal buffer used as argument to split."""
    var start: Int
    """First non-processed byte in buf."""
    var end: Int
    """End of data in buf."""
    var empties: Int
    """Count of successive empty tokens."""
    var scan_called: Bool
    """Scan has been called; buffer is in use."""
    var done: Bool
    """Scan has finished."""
    var err: Error
    """Error encountered during scanning."""

    fn __init__(
        inout self,
        owned reader: R,
        *,
        max_token_size: Int = MAX_SCAN_TOKEN_SIZE,
        token: List[UInt8, True] = List[UInt8, True](capacity=capacity),
        buf: List[UInt8, True] = List[UInt8, True](capacity=capacity),
        start: Int = 0,
        end: Int = 0,
        empties: Int = 0,
        scan_called: Bool = False,
        done: Bool = False,
    ):
        """Initializes a new Scanner.

        Params:
            R: The type of io.Reader.
            split: The split function to use.
            capacity: The capacity of the internal buffer.

        Args:
            reader: The reader to scan.
            max_token_size: The maximum size of a token.
            token: The token buffer.
            buf: The buffer to use for scanning.
            start: The start index of the buffer.
            end: The end index of the buffer.
            empties: The number of empty tokens.
            scan_called: Whether the scan method has been called.
            done: Whether scanning is done.
        """
        self.reader = reader^
        self.max_token_size = max_token_size
        self.token = token
        self.buf = buf
        self.start = start
        self.end = end
        self.empties = empties
        self.scan_called = scan_called
        self.done = done
        self.err = Error()

    fn as_bytes_slice(ref [_]self) -> Span[UInt8, __lifetime_of(self)]:
        """Returns the internal data as a Span[UInt8]."""
        return Span[UInt8, __lifetime_of(self)](self.buf)

    fn current_token_as_bytes_slice(ref [_]self) -> Span[UInt8, __lifetime_of(self)]:
        """Returns the most recent token generated by a call to `Scanner.scan`."""
        return Span[UInt8, __lifetime_of(self)](self.token)

    fn current_token_as_string_slice(ref [_]self) -> StringSlice[__lifetime_of(self)]:
        """Returns the most recent token generated by a call to `Scanner.scan`."""
        return StringSlice[__lifetime_of(self)](unsafe_from_utf8_ptr=self.token.unsafe_ptr(), len=len(self.token))

    fn current_token_as_bytes(self) -> List[UInt8, True]:
        """Returns the most recent token generated by a call to `Scanner.scan`."""
        return self.token

    fn current_token(self) -> String:
        """Returns the most recent token generated by a call to `Scanner.scan`."""
        return self.current_token_as_string_slice()

    fn scan(inout self) -> Bool:
        """Advances the `Scanner` to the next token, which will then be
        available through the `Scanner.current_token_as_bytes`, `Scanner.current_token`,
        `Scanner.current_token_as_bytes_slice`, and `Scanner.current_token_as_string_slice` methods.

        It returns False when there are no more tokens, either by reaching the end of the input or an error.
        After Scan returns False, the `Scanner.set_err` method will return any error that
        occurred during scanning, except if it was `io.EOF` or `Scanner.set_err`.

        `scan` raises an Error if the split function returns too many empty
        tokens without advancing the input. This is a common error mode for
        scanners.

        Returns:
            True if a token was found, False otherwise.
        """
        if self.done:
            return False

        self.scan_called = True
        # Loop until we have a token.
        while True:
            # See if we can get a token with what we already have.
            # If we've run out of data but have an error, give the split function
            # a chance to recover any remaining, possibly empty token.
            if (self.end > self.start) or self.err:
                var advance: Int
                var token = List[UInt8, True](capacity=capacity)
                var err = Error()
                var at_eof = False
                if self.err:
                    at_eof = True
                advance, token, err = split(self.as_bytes_slice()[self.start : self.end], at_eof)
                if err:
                    if str(err) == str(ERR_FINAL_TOKEN):
                        self.token = token
                        self.done = True
                        # When token is not empty, it means the scanning stops
                        # with a trailing token, and thus the return value
                        # should be True to indicate the existence of the token.
                        return len(token) != 0

                    self.set_err(err)
                    return False

                if not self.advance(advance):
                    return False

                self.token = token
                if len(token) != 0:
                    if not self.err or advance > 0:
                        self.empties = 0
                    else:
                        # Returning tokens not advancing input at EOF.
                        self.empties += 1
                        if self.empties > MAX_CONSECUTIVE_EMPTY_READS:
                            panic("bufio.Scan: too many empty tokens without progressing")

                    return True

            # We cannot generate a token with what we are holding.
            # If we've already hit EOF or an I/O error, we are done.
            if self.err:
                # Shut it down.
                self.start = 0
                self.end = 0
                return False

            # Must read more data.
            # First, shift data to beginning of buffer if there's lots of empty space
            # or space is needed.
            if self.start > 0 and (self.end == len(self.buf) or self.start > int(len(self.buf) / 2)):
                memcpy(self.buf.unsafe_ptr(), self.buf.unsafe_ptr().offset(self.start), self.end - self.start)
                self.end -= self.start
                self.start = 0
                self.buf.size = self.end

            # Is the buffer full? If so, resize.
            if self.end == len(self.buf):
                # Guarantee no overflow in the multiplication below.
                if len(self.buf) >= self.max_token_size or len(self.buf) > int(MAX_INT / 2):
                    self.set_err((ERR_TOO_LONG))
                    return False

                var new_size = len(self.buf) * 2
                if new_size == 0:
                    new_size = START_BUF_SIZE

                # Make a new List[UInt8, True] buffer and copy the elements in
                new_size = min(new_size, self.max_token_size)
                var new_buf = self.buf[self.start : self.end]  # slicing returns a new list
                new_buf.reserve(new_size)
                self.buf = new_buf
                self.end -= self.start
                self.start = 0

            # Finally we can read some input. Make sure we don't get stuck with
            # a misbehaving Reader. Officially we don't need to do this, but let's
            # be extra careful: Scanner is for safe, simple jobs.
            var loop = 0
            while True:
                # Catch any reader errors and set the internal error field to that err instead of bubbling it up.
                var dest_ptr = self.buf.unsafe_ptr().offset(self.end)
                var bytes_read: Int
                var err: Error
                bytes_read, err = self.reader._read(dest_ptr, self.buf.capacity - self.buf.size)
                self.buf.size += bytes_read
                if bytes_read < 0 or self.buf.size - self.end < bytes_read:
                    self.set_err(ERR_BAD_READ_COUNT)
                    break

                self.end += bytes_read
                if err:
                    self.set_err(err)
                    break

                if bytes_read > 0:
                    self.empties = 0
                    break

                loop += 1
                if loop > MAX_CONSECUTIVE_EMPTY_READS:
                    self.set_err(io.ERR_NO_PROGRESS)
                    break

    fn set_err(inout self, err: Error) -> None:
        """Set the internal error field to the provided error.

        Args:
            err: The error to set.
        """
        if self.err:
            var value = str(self.err)
            if value == "" or value == str(io.EOF):
                self.err = err
        else:
            self.err = err

    fn advance(inout self, n: Int) -> Bool:
        """Consumes n bytes of the buffer. It reports whether the advance was legal.

        Args:
            n: The number of bytes to advance the buffer by.

        Returns:
            True if the advance was legal, False otherwise.
        """
        if n < 0:
            self.set_err(ERR_NEGATIVE_ADVANCE)
            return False

        if n > self.end - self.start:
            self.set_err(ERR_ADVANCE_TOO_FAR)
            return False

        self.start += n
        return True


alias SplitFunction = fn (data: Span[UInt8], at_eof: Bool) -> (
    Int,
    List[UInt8, True],
    Error,
)
"""Signature of the split function used to tokenize the
input. The arguments are an initial substring of the remaining unprocessed
data and a flag, at_eof, that reports whether the `Reader` has no more data
to give. The return values are the number of bytes to advance the input
and the next token to return to the user, if any, plus an error, if any.

Scanning stops if the function returns an error, in which case some of
the input may be discarded. If that error is `ERR_FINAL_TOKEN`, scanning
stops with no error. A token delivered with `ERR_FINAL_TOKEN`
will be the last token, and an empty token with `ERR_FINAL_TOKEN`
immediately stops the scanning.

Otherwise, the `Scanner` advances the input. If the token is not nil,
the `Scanner` returns it to the user. If the token is nil, the
Scanner reads more data and continues scanning; if there is no more
data--if `at_eof` was True--the `Scanner` returns. If the data does not
yet hold a complete token, for instance if it has no newline while
scanning lines, a `SplitFunction` can return (0, List[UInt8, True](), Error()) to signal the
`Scanner` to read more data Into the slice and try again with a
longer slice starting at the same poInt in the input.

The function is never called with an empty data slice unless at_eof
is True. If `at_eof` is True, however, data may be non-empty and,
as always, holds unprocessed text."""

# Errors returned by Scanner.
alias ERR_TOO_LONG = Error("bufio.Scanner: token too long")
alias ERR_NEGATIVE_ADVANCE = Error("bufio.Scanner: SplitFunction returns negative advance count")
alias ERR_ADVANCE_TOO_FAR = Error("bufio.Scanner: SplitFunction returns advance count beyond input")
alias ERR_BAD_READ_COUNT = Error("bufio.Scanner: Read returned impossible count")


alias ERR_FINAL_TOKEN = Error("final token")
"""Special sentinel error value. It is Intended to be
returned by a split function to indicate that the scanning should stop
with no error. If the token being delivered with this error is not nil,
the token is the last token.

The value is useful to stop processing early or when it is necessary to
deliver a final empty token (which is different from a nil token).
One could achieve the same behavior with a custom error value but
providing one here is tidier."""


alias MAX_SCAN_TOKEN_SIZE = 64 * 1024
"""Maximum size used to buffer a token
unless the user provides an explicit buffer with `Scanner.buffer`.
The actual maximum token size may be smaller as the buffer
may need to include, for instance, a newline."""

alias START_BUF_SIZE = 4096
"""Size of initial allocation for buffer."""


###### split functions ######
fn scan_bytes(data: Span[UInt8], at_eof: Bool) -> (Int, List[UInt8, True], Error):
    """Returns each byte as a token.

    Args:
        data: The data to split.
        at_eof: Whether the data is at the end of the file.

    Returns:
        The number of bytes to advance the input, token in bytes, and an error if one occurred.
    """
    if at_eof and len(data) == 0:
        return 0, List[UInt8, True](), Error()

    return 1, List[UInt8, True](data[0:1]), Error()


fn scan_runes(data: Span[UInt8], at_eof: Bool) -> (Int, List[UInt8, True], Error):
    """Returns each UTF-8 encoded rune as a token.

    Args:
        data: The data to split.
        at_eof: Whether the data is at the end of the file.

    Returns:
        The number of bytes to advance the input, token in bytes, and an error if one occurred.
    """
    if at_eof and len(data) == 0:
        return 0, List[UInt8, True](), Error()

    # Number of bytes of the current character
    var lhs = (((UnsafePointer[Scalar[DType.uint8]].load(data.unsafe_ptr()) >> 7) == 0) * 1).cast[DType.uint8]()
    var rhs = count_leading_zeros(~UnsafePointer[Scalar[DType.uint8]].load(data.unsafe_ptr()))
    var char_length = int(lhs + rhs)

    # Copy N bytes into new pointer and construct List.
    var sp = UnsafePointer[UInt8].alloc(char_length)
    memcpy(sp, data.unsafe_ptr(), char_length)
    var result = List[UInt8, True](unsafe_pointer=sp, size=char_length, capacity=char_length)

    return char_length, result, Error()


fn drop_carriage_return(data: Span[UInt8]) -> List[UInt8, True]:
    """Drops a terminal \\r from the data.

    Args:
        data: The data to strip.

    Returns:
        The stripped data.
    """
    # In the case of a \r ending without a \n, indexing on -1 doesn't work as it finds a null terminator instead of \r.
    if len(data) > 0 and data[-1] == ord("\r"):
        return data[:-1]

    return data


fn scan_lines(data: Span[UInt8], at_eof: Bool) -> (Int, List[UInt8, True], Error):
    """Returns each line of text, stripped of any trailing end-of-line marker. The returned line may
    be empty. The end-of-line marker is one optional carriage return followed
    by one mandatory newline. The last non-empty line of input will be returned even if it has no
    newline.

    Args:
        data: The data to split.
        at_eof: Whether the data is at the end of the file.

    Returns:
        The number of bytes to advance the input.
    """
    if at_eof and len(data) == 0:
        return 0, List[UInt8, True](), Error()

    var i = index_byte(data, ord("\n"))
    if i >= 0:
        # We have a full newline-terminated line.
        return i + 1, drop_carriage_return(data[0:i]), Error()

    # If we're at EOF, we have a final, non-terminated line. Return it.
    # if at_eof:
    return len(data), drop_carriage_return(data), Error()

    # Request more data.
    # return 0


fn is_space(r: UInt8) -> Bool:
    alias ALL_WHITESPACES: String = " \t\n\r\x0b\f"
    if chr(int(r)) in ALL_WHITESPACES:
        return True
    return False


# TODO: Handle runes and utf8 decoding. For now, just assuming single byte length.
fn scan_words(data: Span[UInt8], at_eof: Bool) -> (Int, List[UInt8, True], Error):
    """Returns each space-separated word of text, with surrounding spaces deleted. It will
    never return an empty string.

    Args:
        data: The data to split.
        at_eof: Whether the data is at the end of the file.

    Returns:
        The number of bytes to advance the input, token in bytes, and an error if one occurred.
    """
    # Skip leading spaces.
    var start = 0
    var width = 0
    while start < len(data):
        width = len(data[0])
        if not is_space(data[0]):
            break

        start += width

    # Scan until space, marking end of word.
    var i = 0
    width = 0
    start = 0
    while i < len(data):
        width = len(data[i])
        if is_space(data[i]):
            return i + width, List[UInt8, True](data[start:i]), Error()

        i += width

    # If we're at EOF, we have a final, non-empty, non-terminated word. Return it.
    if at_eof and len(data) > start:
        return len(data), List[UInt8, True](data[start:]), Error()

    # Request more data.
    return start, List[UInt8, True](), Error()
