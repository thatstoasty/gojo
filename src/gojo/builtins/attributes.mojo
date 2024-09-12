fn copy[
    T: CollectionElement, is_trivial: Bool
](inout target: List[T, is_trivial], source: List[T, is_trivial], start: Int = 0) -> Int:
    """Copies the contents of source into target at the same index.

    Args:
        target: The buffer to copy into.
        source: The buffer to copy from.
        start: The index to start copying into.

    Returns:
        The number of bytes copied.
    """
    var count = 0

    for i in range(len(source)):
        if i + start > len(target):
            target[i + start] = source[i]
        else:
            target.append(source[i])
        count += 1

    return count
