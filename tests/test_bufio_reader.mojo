from testing import testing
from gojo.bytes import buffer
from gojo.builtins._bytes import Bytes
from gojo.bufio import Reader


fn test_reader() raises:
    print("Testing reader")
    var s: String = "Hello World!"
    var buf = buffer.new_buffer_string(s)
    var r = Reader(buf)
    var dest = Bytes(256)
    _ = r.read(dest)

    testing.assert_equal(str(dest), s)


fn bufio_reader_tests() raises:
    test_reader()