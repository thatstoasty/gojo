from gojo.unicode import UnicodeString
from tests.wrapper import MojoTest


fn test_unicode_string():
    var test = MojoTest("Testing unicode.UnicodeString")
    var s = UnicodeString("𡨸漢𡨸漢")
    test.assert_equal(s.bytecount(), 14)
    test.assert_equal(len(s), 4)

    var i = 0
    var results = List[String]("𡨸", "漢", "𡨸", "漢")
    for c in s:
        test.assert_equal(String(c), results[i])
        i += 1

    test.assert_equal(String(s[:1]), "𡨸")
    test.assert_equal(String(s[:2]), "𡨸漢")
    # test.assert_equal(String(s[:-1]), "𡨸漢𡨸漢")


fn main():
    test_unicode_string()
