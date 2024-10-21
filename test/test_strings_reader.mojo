from gojo.strings import StringBuilder, Reader
from gojo.bytes import to_string
import gojo.io
import testing


def test_read():
    example = "Hello, World!"
    reader = Reader("Hello, World!")

    # Test reading from the reader.
    buffer = List[UInt8, True](capacity=16)
    bytes_read = reader.read(buffer)
    buffer.append(0)

    testing.assert_equal(bytes_read, len(example))
    testing.assert_equal(String(buffer), "Hello, World!")


def test_read_slice():
    example = "Hello, World!"
    reader = Reader("Hello, World!")

    # Test reading from the reader.
    buffer = List[UInt8, True](capacity=16)
    bytes_read = reader.read(buffer)
    buffer.append(0)

    testing.assert_equal(bytes_read, len(example))
    testing.assert_equal(String(buffer), "Hello, World!")


def test_seek():
    reader = Reader("Hello, World!")

    # Seek to the middle of the reader.
    position = reader.seek(5, io.SEEK_START)
    testing.assert_equal(int(position), 5)


def test_read_and_unread_byte():
    example = "Hello, World!"
    reader = Reader("Hello, World!")

    # Read the first byte from the reader.
    byte = reader.read_byte()
    testing.assert_equal(int(byte[0]), 72)

    # Unread the first byte from the reader. Remaining bytes to be read should be the same as the length of the example string.
    _ = reader.unread_byte()
    testing.assert_equal(len(reader), len(example))


def test_write_to():
    example = "Hello, World!"
    reader = Reader("Hello, World!")

    # Write from the string reader to a StringBuilder.
    builder = StringBuilder()
    _ = reader.write_to(builder)
    testing.assert_equal(str(builder), example)


def test_read_until_delimiter():
    reader = Reader("Hello, World!")

    # Test reading from the reader.
    result = reader.read_until_delimiter(",")
    testing.assert_equal(result, "Hello")
