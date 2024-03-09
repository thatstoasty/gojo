from tests.wrapper import MojoTest
from gojo.builtins._bytes import Bytes
from gojo.bytes import new_reader


fn test_reader() raises:
    var test = MojoTest("Testing bytes.Reader")

    # Create a new reader from string s. It is converted to Bytes upon init.
    var s: String = "Hello World!"
    var buf = new_reader(s)

    # Read the contents of reader into dest
    var dest = Bytes(512)
    _ = buf.read(dest)
    test.assert_equal(str(dest), s)


fn main() raises:
    test_reader()
