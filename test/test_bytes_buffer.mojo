from gojo.bytes.buffer import Buffer
from gojo.bytes import to_string
import testing


def test_read():
    s = "Hello World!"
    buf = Buffer(s)
    dest = List[UInt8, True](capacity=16)
    _ = buf.read(dest)
    testing.assert_equal(to_string(dest), s)


def test_read_byte():
    buf = Buffer("Hello World!")
    result = buf.read_byte()
    testing.assert_equal(int(result), 72)


def test_unread_byte():
    buf = Buffer("Hello World!")
    result = buf.read_byte()
    testing.assert_equal(int(result), 72)
    testing.assert_equal(buf.offset, 1)

    _ = buf.unread_byte()
    testing.assert_equal(buf.offset, 0)


def test_read_span():
    buf = Buffer("Hello World!")
    result = buf.read_span(ord("o"))
    text = List[UInt8, True](result)
    text.append(0)
    testing.assert_equal(String(text), "Hello")


def test_read_string():
    buf = Buffer("Hello World!")
    result = buf.read_string(ord("o"))
    testing.assert_equal(result, "Hello")


def test_next():
    buf = Buffer("Hello World!")
    text = List[UInt8, True](buf.next(5))
    text.append(0)
    testing.assert_equal(String(text), "Hello")


def test_write():
    buf = Buffer(List[UInt8, True](capacity=16))
    _ = buf.write("Hello World!")
    testing.assert_equal(str(buf), "Hello World!")


def test_multiple_writes():
    buf = Buffer(List[UInt8, True](capacity=1200))
    for _ in range(100):
        _ = buf.write("Hello World!")

    testing.assert_equal(len(buf), 1200)
    result = str(buf)
    testing.assert_equal(result[0], "H")
    testing.assert_equal(result[1199], "!")


def test_write_string():
    buf = Buffer(List[UInt8, True](capacity=16))
    _ = buf.write("\nGoodbye World!")
    testing.assert_equal(str(buf), String("\nGoodbye World!"))


def test_write_byte():
    buf = Buffer(List[UInt8, True](capacity=16))
    _ = buf.write_byte(0x41)
    testing.assert_equal(str(buf), String("A"))


def test_buffer():
    b = "Hello World!"
    buf = Buffer(b)
    testing.assert_equal(str(buf), b)

    buf = Buffer(String("Goodbye World!"))
    testing.assert_equal(str(buf), "Goodbye World!")

    buf = Buffer()
    testing.assert_equal(str(buf), "")
