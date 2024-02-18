from tests.test_buffer import buffer_tests
from tests.test_fmt import fmt_tests
from tests.test_io import io_tests
from tests.test_reader import reader_tests


fn main() raises:
    buffer_tests()
    fmt_tests()
    io_tests()
    reader_tests()

    print("All tests passed!")