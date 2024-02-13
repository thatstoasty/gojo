from ..stdlib_extensions.builtins._bytes import bytes, Byte


fn to_string(bytes: bytes) -> String:
    var s: String = ""
    for i in range(len(bytes)):
        # TODO: Resizing isn't really working rn. The grow functions return the wrong index to append new bytes to.
        # This is a hack to ignore the 0 null characters that are used to resize the dynamicvector capacity.
        if bytes[i] != 0:
            let char = chr(int(bytes[i]))
            s += char
    return s


fn to_bytes(s: String) -> bytes:
    # TODO: Len of runes can be longer than one byte
    var b = bytes(size=len(s))
    for i in range(len(s)):
        b[i] = ord((s[i]))
    return b


fn index_byte(b: bytes, c: Byte) -> Int:
    let i = 0
    for i in range(len(b)):
        if b[i] == c:
            return i

    return -1


fn equal(a: bytes, b: bytes) -> Bool:
    return to_string(a) == to_string(b)


fn has_prefix(s: bytes, prefix: bytes) raises -> Bool:
    """Reports whether the byte slice s begins with prefix."""
    let len_comparison = len(s) >= len(prefix)
    let prefix_comparison = equal(s[0 : len(prefix)], prefix)
    return len_comparison and prefix_comparison


fn has_suffix(s: bytes, suffix: bytes) raises -> Bool:
    """Reports whether the byte slice s ends with suffix."""
    let len_comparison = len(s) >= len(suffix)
    let suffix_comparison = equal(s[len(s) - len(suffix) : len(s)], suffix)
    return len_comparison and suffix_comparison


fn trim_null_characters(b: bytes) -> bytes:
    """Limits characters to the ASCII range of 1-127. Excludes null characters, extended characters, and unicode characters.
    """
    var new_b = bytes(len(b))
    for i in range(len(b)):
        if b[i] > 0 and b[i] < 127:
            new_b[i] = b[i]
    return new_b


fn copy(inout target: bytes, source: bytes) -> Int:
    """Copies the contents of source into target at the same index. Returns the number of bytes copied.
    TODO: End of strings include a null character which terminates the string. This is a hack to not write those to the buffer for now.
    TODO: It appends additional values if the source is longer than the target, if not then it overwrites the target.
    """
    var count = 0

    for i in range(len(source)):
        if source[i] != 0:
            if len(target) <= i:
                target._vector.append(source[i])
            else:
                target[i] = source[i]
            count += 1

    # target = trim_null_characters(target)
    return count


fn cap(buffer: bytes) -> Int:
    return buffer._vector.capacity
