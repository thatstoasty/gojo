from tests.wrapper import MojoTest
from gojo.bytes import buffer
from gojo.builtins._bytes import Bytes
from gojo.bufio import Reader


fn test_reader() raises:
    var test = MojoTest("Testing reader")

    # Create a reader from a string buffer
    var s: String = "Hello"
    var buf = buffer.new_buffer_string(s)
    var r = Reader(buf)

    # Read the buffer into Bytes and then add more to Bytes
    var dest = Bytes(256)
    _ = r.read(dest)
    dest.extend(" World!")

    test.assert_equal(dest, "Hello World!")


fn main() raises:
    test_reader()
