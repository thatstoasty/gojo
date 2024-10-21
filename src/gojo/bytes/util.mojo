from utils import Span
from memory import UnsafePointer


fn equals(left: List[Byte, True], right: List[Byte, True]) -> Bool:
    """Reports if `left` and `right` are equal.

    Args:
        left: The first list to compare.
        right: The second list to compare.
    """
    if len(left) != len(right):
        return False
    for i in range(len(left)):
        if left[i] != right[i]:
            return False
    return True


fn has_prefix(bytes: List[Byte, True], prefix: List[Byte, True]) -> Bool:
    """Reports if the list begins with prefix.

    Args:
        bytes: The list to search.
        prefix: The prefix to search for.
    """
    var len_comparison = len(bytes) >= len(prefix)
    var prefix_comparison = equals(bytes[0 : len(prefix)], prefix)
    return len_comparison and prefix_comparison


fn has_suffix(bytes: List[Byte, True], suffix: List[Byte, True]) -> Bool:
    """Reports if the list ends with suffix.

    Args:
        bytes: The list struct to search.
        suffix: The suffix to search for.
    """
    var len_comparison = len(bytes) >= len(suffix)
    var suffix_comparison = equals(bytes[len(bytes) - len(suffix) : len(bytes)], suffix)
    return len_comparison and suffix_comparison


fn index_byte(bytes: List[Byte, True], delim: Byte) -> Int:
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


fn index_byte(bytes: UnsafePointer[Scalar[DType.uint8]], size: Int, delim: Byte) -> Int:
    """Return the index of the first occurrence of the byte `delim`.

    Args:
        bytes: The list to search.
        size: The number of elements stored at the pointer address.
        delim: The byte to search for.

    Returns:
        The index of the first occurrence of the byte `delim`.
    """
    for i in range(size):
        if Byte(bytes[i]) == delim:
            return i

    return -1


fn index_byte(bytes: Span[Byte], delim: Byte) -> Int:
    """Return the index of the first occurrence of the byte `delim`.

    Args:
        bytes: The Span to search.
        delim: The byte to search for.

    Returns:
        The index of the first occurrence of the byte `delim`.
    """
    for i in range(len(bytes)):
        if bytes[i] == delim:
            return i

    return -1


fn to_string(bytes: List[Byte, True]) -> String:
    """Makes a deep copy of the list supplied and converts it to a string.
    If it's not null terminated, it will append a null byte.

    Args:
        bytes: The list to convert.

    Returns:
        A String built from the list of bytes.
    """
    var copy = List[Byte](bytes)
    if copy[-1] != 0:
        copy.append(0)
    return String(copy^)
