from tests.wrapper import MojoTest
from gojo.builtins._bytes import Bytes
from gojo.bytes import new_buffer, new_reader


fn test_buffer_read() raises:
    var test = MojoTest("Testing bytes.Buffer read")
    var s: String = "Hello World!"
    var buf = new_buffer(s)
    var dest = Bytes(256)
    _ = buf.read(dest)
    test.assert_equal(str(dest), s)


fn test_buffer_write() raises:
    var test = MojoTest("Testing bytes.Buffer write")
    var b = Bytes(256)
    var buf = new_buffer(b ^)
    _ = buf.write(Bytes("Hello World!"))
    test.assert_equal(str(buf), String("Hello World!"))

    print("Testing write_string")
    _ = buf.write_string("\nGoodbye World!")
    test.assert_equal(str(buf), String("Hello World!\nGoodbye World!"))

    print("Testing write_byte")
    _ = buf.write_byte(0x41)
    test.assert_equal(str(buf), String("Hello World!\nGoodbye World!A"))


fn test_reader() raises:
    var test = MojoTest("Testing bytes.Reader")

    # Create a new reader from string s. It is converted to Bytes upon init.
    var s: String = "Hello World!"
    var buf = new_reader(s)

    # Read the contents of reader into dest
    var dest = Bytes()
    _ = buf.read(dest)
    test.assert_equal(str(dest), s)


fn main() raises:
    test_buffer_read()
    test_buffer_write()
    test_reader()
