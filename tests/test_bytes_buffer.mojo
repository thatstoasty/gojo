from tests.wrapper import MojoTest
from gojo.builtins.bytes import Byte
from gojo.bytes import new_buffer


fn test_read() raises:
    var test = MojoTest("Testing bytes.Buffer.read")
    var s: String = "Hello World!"
    var buf = new_buffer(s)
    var dest = List[Byte](capacity=256)
    _ = buf.read(dest)
    dest.append(0)
    test.assert_equal(String(dest), s)


fn test_read_byte() raises:
    var test = MojoTest("Testing bytes.Buffer.read_byte")
    var s: String = "Hello World!"
    var buf = new_buffer(s)
    var result = buf.read_byte()
    test.assert_equal(int(result[0]), 72)


fn test_unread_byte() raises:
    var test = MojoTest("Testing bytes.Buffer.unread_byte")
    var s: String = "Hello World!"
    var buf = new_buffer(s)
    var result = buf.read_byte()
    test.assert_equal(int(result[0]), 72)
    test.assert_equal(buf.off, 1)

    _ = buf.unread_byte()
    test.assert_equal(buf.off, 0)


fn test_read_bytes() raises:
    var test = MojoTest("Testing bytes.Buffer.read_bytes")
    var s: String = "Hello World!"
    var buf = new_buffer(s)
    var result = buf.read_bytes(ord("o"))
    var text = result[0]
    text.append(0)
    test.assert_equal(String(text), String("Hello"))


fn test_read_slice() raises:
    var test = MojoTest("Testing bytes.Buffer.read_slice")
    var s: String = "Hello World!"
    var buf = new_buffer(s)
    var result = buf.read_slice(5)
    var text = result[0]
    text.append(0)
    test.assert_equal(String(text), String("Hello"))


fn test_read_string() raises:
    var test = MojoTest("Testing bytes.Buffer.read_string")
    var s: String = "Hello World!"
    var buf = new_buffer(s)
    var result = buf.read_string(ord("o"))
    test.assert_equal(String(result[0]), String("Hello"))


fn test_next() raises:
    var test = MojoTest("Testing bytes.Buffer.next")
    var buf = new_buffer("Hello World!")
    var text = buf.next(5)
    text.append(0)
    test.assert_equal(String(text), String("Hello"))


fn test_write() raises:
    var test = MojoTest("Testing bytes.Buffer.write")
    var b = List[Byte](capacity=16)
    var buf = new_buffer(b^)
    _ = buf.write(String("Hello World!").as_bytes())
    test.assert_equal(str(buf), String("Hello World!"))


fn test_write_string() raises:
    var test = MojoTest("Testing bytes.Buffer.write_string")
    var b = List[Byte](capacity=16)
    var buf = new_buffer(b^)

    _ = buf.write_string("\nGoodbye World!")
    test.assert_equal(str(buf), String("\nGoodbye World!"))


fn test_write_byte() raises:
    var test = MojoTest("Testing bytes.Buffer.write_byte")
    var b = List[Byte](capacity=16)
    var buf = new_buffer(b^)
    _ = buf.write_byte(0x41)
    test.assert_equal(str(buf), String("A"))


fn test_new_buffer() raises:
    var test = MojoTest("Testing bytes.new_buffer")
    var b = String("Hello World!").as_bytes()
    var buf = new_buffer(b^)
    test.assert_equal(str(buf), "Hello World!")

    buf = new_buffer("Goodbye World!")
    test.assert_equal(str(buf), "Goodbye World!")

    buf = new_buffer()
    test.assert_equal(str(buf), "")


fn main() raises:
    test_read()
    test_read_byte()
    test_unread_byte()
    test_read_bytes()
    test_read_string()
    test_next()
    test_write()
    test_write_string()
    test_write_byte()
    test_new_buffer()
