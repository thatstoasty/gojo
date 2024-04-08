
fn equal_fold(s: String, t: String) -> Bool:
    """EqualFold is [strings.EqualFold], ASCII only. It reports whether s and t
    are equal, ASCII-case-insensitively."""
    if len(s) != len(t):
        return False

    var i = 0
    while i < len(s):
        if s[i].lower() != t[i].lower():
            return False
        i += 1

    return True
