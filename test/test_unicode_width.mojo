from gojo.unicode import string_width, rune_width
import testing


def test_string_width_east_asian():
    var s: String = "𡨸漢𡨸漢"

    testing.assert_equal(string_width(s), 8, msg="The length of 𡨸漢𡨸漢 should be 8.")
    for r in s:
        testing.assert_equal(rune_width(ord(r)), 2, msg="The width of each character should be 2.")
        testing.assert_equal(string_width(r), 2, msg="The width of each character should be 2.")


def test_string_width_ascii():
    var ascii: String = "Hello, World!"

    testing.assert_equal(string_width(ascii), 13)
    for r in ascii:
        testing.assert_equal(rune_width(ord(r)), 1, msg="The width of each character should be 1.")
        testing.assert_equal(string_width(r), 1, msg="The width of each character should be 1.")


def test_string_width_emoji():
    var s: String = "🔥🔥🔥🔥"

    testing.assert_equal(string_width(s), 8)
    for r in s:
        testing.assert_equal(rune_width(ord(r)), 2, msg="The width of each character should be 2.")
        testing.assert_equal(string_width(r), 2, msg="The width of each character should be 2.")
