from testing import testing
from gojo.builtins ._bytes import Bytes
from gojo.bytes.buffer import new_buffer_string, new_buffer, Buffer


fn test_read() raises:
    print("Testing read")
    var s: String = "Hello World!"
    var buf = new_buffer_string(s)
    var dest = Bytes(256)
    _ = buf.read(dest)
    testing.assert_equal(str(dest), s)


fn test_write() raises:
    print("Testing write")
    var b = Bytes(256)
    var buf = new_buffer(b ^)
    _ = buf.write(Bytes("Hello World!"))
    testing.assert_equal(str(buf), String("Hello World!"))

    print("Testing write_string")
    _ = buf.write_string("\nGoodbye World!")
    testing.assert_equal(str(buf), String("Hello World!\nGoodbye World!"))

    print("Testing write_byte")
    _ = buf.write_byte(0x41)
    testing.assert_equal(str(buf), String("Hello World!\nGoodbye World!A"))


fn buffer_tests() raises:
    test_write()
    test_read()