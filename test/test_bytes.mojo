from utils import Span
from gojo.bytes import index_byte
import testing


def test_index_byte():
    testing.assert_equal(index_byte("hello\n".as_bytes(), ord("\n")), 5)
