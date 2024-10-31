from gojo.bytes.buffer import Buffer
from gojo.bytes import to_string
import testing


def test_read():
    buf = Buffer("Hello World!")
    dest = List[UInt8, True](capacity=16)
    _ = buf.read(dest)
    testing.assert_equal(to_string(dest), "Hello World!")


def test_read_byte():
    buf = Buffer("Hello World!")
    testing.assert_equal(buf.read_byte(), 72)


def test_unread_byte():
    buf = Buffer("Hello World!")
    testing.assert_equal(buf.read_byte(), 72)
    testing.assert_equal(buf.offset, 1)

    buf.unread_byte()
    testing.assert_equal(buf.offset, 0)


def test_read_span():
    buf = Buffer("Hello World!")
    text = List[UInt8, True](buf.read_span(ord("o")))
    testing.assert_equal(to_string(text), "Hello")


def test_read_string():
    buf = Buffer("Hello World!")
    testing.assert_equal(buf.read_string(ord("o")), "Hello")


def test_next():
    buf = Buffer("Hello World!")
    text = List[UInt8, True](buf.next(5))
    testing.assert_equal(to_string(text), "Hello")


def test_write():
    buf = Buffer(List[UInt8, True](capacity=16))
    buf.write("Hello World!")
    testing.assert_equal(buf.consume(), "Hello World!")


def test_multiple_writes():
    buf = Buffer(List[UInt8, True](capacity=1200))
    for _ in range(100):
        buf.write("Hello World!")

    testing.assert_equal(len(buf), 1200)
    text = buf.as_string_slice()
    testing.assert_equal(text[0], "H")
    testing.assert_equal(text[1199], "!")


def test_write_string():
    buf = Buffer(List[UInt8, True](capacity=16))
    buf.write("\nGoodbye World!")
    testing.assert_equal(buf.consume(), "\nGoodbye World!")


def test_write_byte():
    buf = Buffer(List[UInt8, True](capacity=16))
    buf.write_byte(0x41)
    testing.assert_equal(buf.consume(), "A")


def test_buffer():
    buf = Buffer("Hello World!")
    testing.assert_equal(buf.consume(reuse=True), "Hello World!")

    buf.write("Goodbye World!")
    testing.assert_equal(buf.consume(reuse=True), "Goodbye World!")
    testing.assert_equal(buf.consume(reuse=True), "")
