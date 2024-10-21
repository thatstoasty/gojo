import gojo.bytes
import gojo.io
import gojo.strings
from gojo.bytes import to_string
import testing


def test_read_all():
    reader = bytes.Reader("0123456789")
    result = io.read_all(reader)
    testing.assert_equal(to_string(result), "0123456789")


def test_read_at_least():
    reader = bytes.Reader("0123456789")
    dest = List[Byte, True](capacity=5)
    result = io.read_at_least(reader, dest, 5)
    testing.assert_true(result >= 5)
    testing.assert_equal(to_string(dest[0:5]), "01234")


def test_read_full():
    reader = strings.Reader("0123456789")
    dest = List[Byte, True](capacity=5)
    result = io.read_full(reader, dest)
    testing.assert_true(result == 5)
    testing.assert_equal(to_string(dest), "01234")
