from tests.wrapper import MojoTest
from gojo.bytes.buffer import Buffer


fn test_read():
    var test = MojoTest("Testing bytes.Buffer.read")
    var s: String = "Hello World!"
    var buf = Buffer(buf=s.as_bytes())
    var dest = List[UInt8, True](capacity=16)
    _ = buf.read(dest)
    dest.append(0)
    test.assert_equal(String(dest), s)


fn test_read_byte():
    var test = MojoTest("Testing bytes.Buffer.read_byte")
    var s: String = "Hello World!"
    var buf = Buffer(buf=s.as_bytes())
    var result = buf.read_byte()
    test.assert_equal(int(result[0]), 72)


fn test_unread_byte():
    var test = MojoTest("Testing bytes.Buffer.unread_byte")
    var s: String = "Hello World!"
    var buf = Buffer(buf=s.as_bytes())
    var result = buf.read_byte()
    test.assert_equal(int(result[0]), 72)
    test.assert_equal(buf.offset, 1)

    _ = buf.unread_byte()
    test.assert_equal(buf.offset, 0)


fn test_read_bytes():
    var test = MojoTest("Testing bytes.Buffer.read_bytes")
    var s: String = "Hello World!"
    var buf = Buffer(buf=s.as_bytes())
    var result = buf.read_bytes(ord("o"))
    var text = result[0]
    text.append(0)
    test.assert_equal(String(text), String("Hello"))


fn test_read_slice():
    var test = MojoTest("Testing bytes.Buffer.read_slice")
    var s: String = "Hello World!"
    var buf = Buffer(buf=s.as_bytes())
    var result = buf.read_slice(ord("o"))
    var text = List[UInt8, True](result[0])
    text.append(0)
    test.assert_equal(String(text), String("Hello"))


fn test_read_string():
    var test = MojoTest("Testing bytes.Buffer.read_string")
    var s: String = "Hello World!"
    var buf = Buffer(buf=s.as_bytes())
    var result = buf.read_string(ord("o"))
    test.assert_equal(result[0], String("Hello"))


fn test_next():
    var test = MojoTest("Testing bytes.Buffer.next")
    var buf = Buffer(buf=String("Hello World!").as_bytes())
    var text = List[UInt8, True](buf.next(5))
    text.append(0)
    test.assert_equal(String(text), String("Hello"))


fn test_write():
    var test = MojoTest("Testing bytes.Buffer.write")
    var b = List[UInt8, True](capacity=16)
    var buf = Buffer(buf=b^)
    _ = buf.write(String("Hello World!").as_bytes_slice())
    test.assert_equal(str(buf), String("Hello World!"))


fn test_muliple_writes():
    var test = MojoTest("Testing bytes.Buffer.write multiple times")
    var b = List[UInt8, True](capacity=1200)
    var buf = Buffer(buf=b^)
    var text = String("Hello World!").as_bytes_slice()
    for _ in range(100):
        _ = buf.write(text)

    test.assert_equal(len(buf), 1200)
    var result = str(buf)
    test.assert_equal(result[0], "H")
    test.assert_equal(result[1199], "!")


fn test_write_string():
    var test = MojoTest("Testing bytes.Buffer.write_string")
    var b = List[UInt8, True](capacity=16)
    var buf = Buffer(buf=b^)

    _ = buf.write_string("\nGoodbye World!")
    test.assert_equal(str(buf), String("\nGoodbye World!"))


fn test_write_byte():
    var test = MojoTest("Testing bytes.Buffer.write_byte")
    var b = List[UInt8, True](capacity=16)
    var buf = Buffer(buf=b^)
    _ = buf.write_byte(0x41)
    test.assert_equal(str(buf), String("A"))


fn test_buffer():
    var test = MojoTest("Testing bytes.Buffer")
    var b = String("Hello World!").as_bytes()
    var buf = Buffer(buf=b^)
    test.assert_equal(str(buf), "Hello World!")

    buf = Buffer(buf=String("Goodbye World!").as_bytes())
    test.assert_equal(str(buf), "Goodbye World!")

    buf = Buffer()
    test.assert_equal(str(buf), "")


fn main():
    test_read()
    test_read_byte()
    test_unread_byte()
    test_read_slice()
    test_read_bytes()
    test_read_string()
    test_next()
    test_write()
    test_write_string()
    test_write_byte()
    test_muliple_writes()
    test_buffer()
