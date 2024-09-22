"""Almost all of the actual implementation in this module was written by @mzaks (https://github.com/mzaks)!
This would not be possible without his help.
"""

from algorithm.functional import vectorize
from sys.info import simdwidthof


alias simd_width_u8 = simdwidthof[DType.uint8]()


fn rune_count_in_string(s: String) -> Int:
    """Count the number of runes in a string.

    Args:
        s: The string to count runes in.

    Returns:
        The number of runes in the string.
    """
    var string_byte_length = len(s)
    var result = 0

    @parameter
    fn count[simd_width: Int](offset: Int):
        result += int(((s.unsafe_ptr().load[width=simd_width](offset) >> 6) != 0b10).cast[DType.uint8]().reduce_add())

    vectorize[count, simd_width_u8](string_byte_length)
    return result


alias SURROGATE_MIN: UInt32 = 0xD800
alias SURROGATE_MAX: UInt32 = 0xDFFF

alias t1 = 0b00000000
alias tx = 0b10000000
alias t2 = 0b11000000
alias t3 = 0b11100000
alias t4 = 0b11110000
alias t5 = 0b11111000

alias maskx = 0b00111111
alias mask2 = 0b00011111
alias mask3 = 0b00001111
alias mask4 = 0b00000111

alias RUNE1_MAX = 1 << 7 - 1
alias RUNE2_MAX = 1 << 11 - 1
alias RUNE3_MAX = 1 << 16 - 1

alias RUNE_ERROR = ord("�")

alias RUNE_ERROR_BYTE0: UInt8 = t3 | (RUNE_ERROR >> 12)
alias RUNE_ERROR_BYTE1: UInt8 = tx | (RUNE_ERROR >> 6) & maskx
alias RUNE_ERROR_BYTE2: UInt8 = tx | RUNE_ERROR & maskx


fn append_rune_non_ascii(inout p: List[UInt8, True], r: UInt32) -> None:
    """Appends the UTF-8 encoding of Unicode code point `r` to the
    buffer, returning the new buffer.

    Args:
        p: The buffer to append to.
        r: The Unicode code point to write to the buffer.

    Returns:
        The new buffer.
    """
    if r <= RUNE2_MAX:
        p.append(t2 | (r.cast[DType.uint8]() >> 6))
        p.append(tx | (r.cast[DType.uint8]()) & maskx)

    elif r < SURROGATE_MIN or (SURROGATE_MAX < r and r <= RUNE3_MAX):
        p.append(t3 | (r.cast[DType.uint8]() >> 12))
        p.append(tx | (r.cast[DType.uint8]() >> 6) & maskx)
        p.append(tx | (r.cast[DType.uint8]()) & maskx)

    elif r > RUNE3_MAX and r <= MAX_RUNE:
        p.append(t4 | (r.cast[DType.uint8]() >> 18))
        p.append(tx | (r.cast[DType.uint8]() >> 12) & maskx)
        p.append(tx | (r.cast[DType.uint8]() >> 6) & maskx)
        p.append(tx | (r.cast[DType.uint8]()) & maskx)

    else:
        p.append(0xEF)
        p.append(0xBF)
        p.append(0xBD)
