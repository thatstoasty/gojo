from tests.wrapper import MojoTest
from gojo.strings import StringBuilder, Reader, new_reader
import gojo.io


fn test_read() raises:
    var test = MojoTest("Testing strings.Reader.read")
    var example: String = "Hello, World!"
    var reader = new_reader("Hello, World!")

    # Test reading from the reader.
    var buffer = List[UInt8](capacity=16)
    var bytes_read = reader.read(buffer)
    buffer.append(0)

    test.assert_equal(bytes_read[0], len(example))
    test.assert_equal(String(buffer), "Hello, World!")


fn test_read_slice() raises:
    var test = MojoTest("Testing strings.Reader.read")
    var example: String = "Hello, World!"
    var reader = new_reader("Hello, World!")

    # Test reading from the reader.
    var buffer = List[UInt8](capacity=16)
    var bytes_read = reader.read(buffer)
    buffer.append(0)

    test.assert_equal(bytes_read[0], len(example))
    test.assert_equal(String(buffer), "Hello, World!")


fn test_read_at() raises:
    var test = MojoTest("Testing strings.Reader.read_at")
    var example: String = "Hello, World!"
    var reader = new_reader("Hello, World!")

    # Test reading from the reader.
    var buffer = List[UInt8](capacity=128)
    var bytes_read = reader.read_at(buffer, 7)
    buffer.append(0)

    test.assert_equal(bytes_read[0], len(example[7:]))
    test.assert_equal(String(buffer), "World!")


fn test_seek() raises:
    var test = MojoTest("Testing strings.Reader.seek")
    var reader = new_reader("Hello, World!")

    # Seek to the middle of the reader.
    var position = reader.seek(5, io.SEEK_START)
    test.assert_equal(int(position[0]), 5)


fn test_read_and_unread_byte() raises:
    var test = MojoTest("Testing strings.Reader.read_byte and strings.Reader.unread_byte")
    var example: String = "Hello, World!"
    var reader = new_reader("Hello, World!")

    # Read the first byte from the reader.
    var byte = reader.read_byte()
    test.assert_equal(int(byte[0]), 72)

    # Unread the first byte from the reader. Remaining bytes to be read should be the same as the length of the example string.
    _ = reader.unread_byte()
    test.assert_equal(len(reader), len(example))


fn test_write_to() raises:
    var test = MojoTest("Testing strings.Reader.write_to")
    var example: String = "Hello, World!"
    var reader = new_reader("Hello, World!")

    # Write from the string reader to a StringBuilder.
    var builder = StringBuilder()
    _ = reader.write_to(builder)
    test.assert_equal(str(builder), example)


fn main() raises:
    test_read()
    test_read_at()
    test_seek()
    test_read_and_unread_byte()
    test_write_to()
    test_read_slice()
