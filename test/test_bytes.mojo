from utils import Span
from gojo.bytes import index_byte
import testing


def test_index_byte():
    var bytes = String("hello\n").as_bytes()
    testing.assert_equal(index_byte(Span(bytes), ord("\n")), 5)
