from gojo.bytes.buffer import Buffer
from gojo.builtins.bytes import to_string
import testing


def test_read():
    var s = "Hello World!"
    var buf = Buffer(s)
    var dest = List[UInt8, True](capacity=16)
    _ = buf.read(dest)
    testing.assert_equal(to_string(dest), s)


def test_read_byte():
    var buf = Buffer("Hello World!")
    var result = buf.read_byte()
    testing.assert_equal(int(result[0]), 72)


def test_unread_byte():
    var buf = Buffer("Hello World!")
    var result = buf.read_byte()
    testing.assert_equal(int(result[0]), 72)
    testing.assert_equal(buf.offset, 1)

    _ = buf.unread_byte()
    testing.assert_equal(buf.offset, 0)


def test_read_bytes():
    var buf = Buffer("Hello World!")
    var result = buf.read_bytes(ord("o"))
    testing.assert_equal(to_string(result[0]), "Hello")


def test_read_slice():
    var buf = Buffer("Hello World!")
    var result = buf.read_slice(ord("o"))
    var text = List[UInt8, True](result[0])
    text.append(0)
    testing.assert_equal(String(text), "Hello")


def test_read_string():
    var buf = Buffer("Hello World!")
    var result = buf.read_string(ord("o"))
    testing.assert_equal(result[0], "Hello")


def test_next():
    var buf = Buffer("Hello World!")
    var text = List[UInt8, True](buf.next(5))
    text.append(0)
    testing.assert_equal(String(text), "Hello")


def test_write():
    var buf = Buffer(List[UInt8, True](capacity=16))
    _ = buf.write("Hello World!".as_bytes_slice())
    testing.assert_equal(str(buf), "Hello World!")


def test_muliple_writes():
    var buf = Buffer(List[UInt8, True](capacity=1200))
    var text = "Hello World!".as_bytes_slice()
    for _ in range(100):
        _ = buf.write(text)

    testing.assert_equal(len(buf), 1200)
    var result = str(buf)
    testing.assert_equal(result[0], "H")
    testing.assert_equal(result[1199], "!")


def test_write_string():
    var buf = Buffer(List[UInt8, True](capacity=16))
    _ = buf.write_string("\nGoodbye World!")
    testing.assert_equal(str(buf), String("\nGoodbye World!"))


def test_write_byte():
    var buf = Buffer(List[UInt8, True](capacity=16))
    _ = buf.write_byte(0x41)
    testing.assert_equal(str(buf), String("A"))


def test_buffer():
    var b = "Hello World!"
    var buf = Buffer(b)
    testing.assert_equal(str(buf), b)

    buf = Buffer(String("Goodbye World!"))
    testing.assert_equal(str(buf), "Goodbye World!")

    buf = Buffer()
    testing.assert_equal(str(buf), "")
