from gojo.strings import StringBuilder, Reader
from gojo.bytes import to_string
import gojo.io
import testing


def test_read():
    var example: String = "Hello, World!"
    var reader = Reader("Hello, World!")

    # Test reading from the reader.
    var buffer = List[UInt8, True](capacity=16)
    var bytes_read = reader.read(buffer)
    buffer.append(0)

    testing.assert_equal(bytes_read[0], len(example))
    testing.assert_equal(String(buffer), "Hello, World!")


def test_read_slice():
    var example: String = "Hello, World!"
    var reader = Reader("Hello, World!")

    # Test reading from the reader.
    var buffer = List[UInt8, True](capacity=16)
    var bytes_read = reader.read(buffer)
    buffer.append(0)

    testing.assert_equal(bytes_read[0], len(example))
    testing.assert_equal(String(buffer), "Hello, World!")


def test_read_at():
    var example: String = "Hello, World!"
    var reader = Reader("Hello, World!")

    # Test reading from the reader.
    var buffer = List[UInt8, True](capacity=128)
    var bytes_read = reader.read_at(buffer, 7)
    buffer.append(0)

    testing.assert_equal(bytes_read[0], len(example[7:]))
    testing.assert_equal(String(buffer), "World!")


def test_seek():
    var reader = Reader("Hello, World!")

    # Seek to the middle of the reader.
    var position = reader.seek(5, io.SEEK_START)
    testing.assert_equal(int(position[0]), 5)


def test_read_and_unread_byte():
    var example: String = "Hello, World!"
    var reader = Reader("Hello, World!")

    # Read the first byte from the reader.
    var byte = reader.read_byte()
    testing.assert_equal(int(byte[0]), 72)

    # Unread the first byte from the reader. Remaining bytes to be read should be the same as the length of the example string.
    _ = reader.unread_byte()
    testing.assert_equal(len(reader), len(example))


def test_write_to():
    var example: String = "Hello, World!"
    var reader = Reader("Hello, World!")

    # Write from the string reader to a StringBuilder.
    var builder = StringBuilder()
    _ = reader.write_to(builder)
    testing.assert_equal(str(builder), example)


def test_read_until_delimiter():
    var reader = Reader("Hello, World!")

    # Test reading from the reader.
    var result = reader.read_until_delimiter(",")
    testing.assert_equal(result, "Hello")
