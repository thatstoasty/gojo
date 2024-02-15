from gojo.bytes.buffer import new_buffer_string, new_buffer, Buffer
from gojo.bytes.util import to_bytes, to_string
from gojo.stdlib_extensions.builtins import bytes
from testing import testing


fn test_read() raises:
    print("Testing read")
    var s: String = "Hello World!"
    var buf = new_buffer_string(s)
    var dest = bytes(256)
    _ = buf.read(dest)
    testing.assert_equal(to_string(dest), s)


fn test_write() raises:
    print("Testing write")
    var b = bytes(256)
    var buf = new_buffer(b)
    _ = buf.write(to_bytes("Hello World!"))
    testing.assert_equal(buf.string(), String("Hello World!"))

    print("Testing write_string")
    _ = buf.write_string("\nGoodbye World!")
    testing.assert_equal(buf.string(), String("Hello World!\nGoodbye World!"))

    print("Testing write_byte")
    _ = buf.write_byte(0x41)
    testing.assert_equal(buf.string(), String("Hello World!\nGoodbye World!A"))


fn main() raises:
    test_write()
    test_read()
