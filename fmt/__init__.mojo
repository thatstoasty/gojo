alias c_char = UInt8
alias c_int = Int32


fn printf[*T: AnyType](format: Pointer[c_char], *args: *T) -> c_int:
    """Libc POSIX `printf` function
    Reference: https://man7.org/linux/man-pages/man3/fprintf.3p.html
    Fn signature: int printf(const char *restrict format, ...).

    Args: format: A pointer to a C string containing the format.
        args: The optional arguments.
    Returns: The number of bytes written or -1 in case of failure.
    """
    return external_call[
        "printf",
        c_int,  # FnName, RetType
        Pointer[c_char],  # Args
    ](format, args)


fn sprintf[
    *T: AnyType
](s: Pointer[c_char], format: Pointer[c_char], *args: *T) -> c_int:
    """Libc POSIX `sprintf` function
    Reference: https://man7.org/linux/man-pages/man3/fprintf.3p.html
    Fn signature: int sprintf(char *restrict s, const char *restrict format, ...).

    Args: s: A pointer to a buffer to store the result.
        format: A pointer to a C string containing the format.
        args: The optional arguments.
    Returns: The number of bytes written or -1 in case of failure.
    """
    return external_call[
        "sprintf", c_int, Pointer[c_char], Pointer[c_char]  # FnName, RetType  # Args
    ](s, format, args)