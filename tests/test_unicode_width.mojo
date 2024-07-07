from gojo.unicode import string_width, rune_width, UnicodeString
from tests.wrapper import MojoTest


fn test_string_width():
    var test = MojoTest("Testing unicode.string_width and unicode.rune_width")
    var ascii = "Hello, World!"
    var s: String = "𡨸漢𡨸漢"
    test.assert_equal(string_width(s), 8)
    test.assert_equal(string_width(ascii), 13)

    for r in UnicodeString(s):
        test.assert_equal(rune_width(ord(String(r))), 2)

    for r in UnicodeString(ascii):
        test.assert_equal(rune_width(ord(String(r))), 1)


fn main():
    test_string_width()
