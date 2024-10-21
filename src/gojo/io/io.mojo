from .traits import Reader, ERR_SHORT_BUFFER, ERR_UNEXPECTED_EOF, EOF


alias BUFFER_SIZE = 4096
"""The default buffer size for reading and writing operations."""


fn read_at_least[R: Reader, //](inout reader: R, inout dest: List[Byte, True], min: Int) raises -> Int:
    """Reads from `reader` into `dest` until it has read at least `min` bytes.
    If `reader` raises an Error having read at least min bytes, the error is dropped.

    Args:
        reader: The reader to read from.
        dest: The buffer to read into.
        min: The minimum number of bytes to read.

    Raises:
        `EOF`: When no bytes were read.
        `ERR_SHORT_BUFFER`: If `min` is greater than the capacity of `dest`.
        `ERR_UNEXPECTED_EOF`: If an `EOF` happens after reading some, but not all the bytes.

    Returns:
        The number of bytes read. `n >= min` if and only if err is empty.
    """
    if dest.capacity < min:
        raise io.ERR_SHORT_BUFFER

    bytes_read = 0
    while bytes_read < min:
        try:
            bytes_read += reader.read(dest)
        except e:
            # If read raised, but we still read the minimum number of bytes, we return anyway.
            if bytes_read >= min:
                return bytes_read

            if str(e) != EOF:
                raise e

    # If we read some bytes, but not all the bytes we expected, we raise an error.
    if bytes_read > 0 and bytes_read < min:
        raise ERR_UNEXPECTED_EOF

    return bytes_read


fn read_full[R: Reader, //](inout reader: R, inout dest: List[Byte, True]) raises -> Int:
    """Reads exactly `len(dest)` bytes from `reader` into `dest`.
    If `reader` raises an Error having read at least `len(dest)` bytes, the error is dropped.

    Args:
        reader: The reader to read from.
        dest: The buffer to read into.

    Raises:
        `EOF`: When no bytes were read.
        `ERR_SHORT_BUFFER`: If `len(dest)` is greater than the capacity of `dest`.
        `ERR_UNEXPECTED_EOF`: If an `EOF` happens after reading some, but not all the bytes.

    Returns:
        The number of bytes read, should equal to `len(dest)`.
    """
    return read_at_least(reader, dest, dest.capacity)


fn read_all[R: Reader, //](inout reader: R) raises -> List[Byte, True]:
    """Reads from `reader` until an Error or `EOF` and returns the data it read.

    Args:
        reader: The reader to read from.

    Returns:
        The data read.
    """
    dest = List[Byte, True](capacity=BUFFER_SIZE)
    while True:
        try:
            _ = reader.read(dest)
            if dest.size == dest.capacity:
                dest.reserve(dest.capacity * 2)
        except e:
            if str(e) != EOF:
                raise e

            return dest
