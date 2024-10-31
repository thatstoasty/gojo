from utils import Span, StringSlice


fn equals(left: Span[Byte], right: Span[Byte]) -> Bool:
    """Reports if `left` and `right` are equal.

    Args:
        left: The first bytes to compare.
        right: The second bytes to compare.
    """
    if len(left) != len(right):
        return False

    for i in range(len(left)):
        if left[i] != right[i]:
            return False
    return True


fn has_prefix(bytes: Span[Byte], prefix: Span[Byte]) -> Bool:
    """Reports if the list begins with prefix.

    Args:
        bytes: The bytes to search.
        prefix: The prefix to search for.
    """
    if len(bytes) < len(prefix):
        return False

    if not equals(bytes[0 : len(prefix)], prefix):
        return False
    return True


fn has_suffix(bytes: Span[Byte], suffix: Span[Byte]) -> Bool:
    """Reports if the list ends with suffix.

    Args:
        bytes: The bytes to search.
        suffix: The suffix to search for.
    """
    if len(bytes) < len(suffix):
        return False

    if not equals(bytes[len(bytes) - len(suffix) : len(bytes)], suffix):
        return False
    return True


fn index_byte(bytes: Span[Byte], delim: Byte) -> Int:
    """Return the index of the first occurrence of the byte `delim`.

    Args:
        bytes: The list to search.
        delim: The byte to search for.

    Returns:
        The index of the first occurrence of the byte `delim`.
    """
    for i in range(len(bytes)):
        if bytes[i] == delim:
            return i

    return -1


fn to_string(bytes: List[Byte, True]) -> String:
    return StringSlice(unsafe_from_utf8=Span(bytes))


fn to_string(bytes: Span[Byte]) -> String:
    return StringSlice(unsafe_from_utf8=bytes)
