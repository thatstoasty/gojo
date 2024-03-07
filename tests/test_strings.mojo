from time import now
from tests.wrapper import MojoTest
from gojo.strings import StringBuilder, Reader, new_reader
from gojo.builtins import Bytes
import gojo.io

fn test_string_builder() raises:
    var test = MojoTest("Testing strings.StringBuilder")
    # Create a string from the buffer
    var builder = StringBuilder()

    for i in range(3):
        _ = builder.write_string("Lorem ipsum dolor sit amet ")

    test.assert_equal(
        str(builder),
        (
            "Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor"
            " sit amet "
        ),
    )


fn test_string_reader() raises:
    var test = MojoTest("Testing strings.Reader")
    var example: String = "Hello, World!"
    var reader = new_reader("Hello, World!")

    # Test reading from the reader.
    var buffer = Bytes()
    var bytes_read = reader.read(buffer)

    test.assert_equal(bytes_read, len(example))
    test.assert_equal(str(buffer), "Hello, World!")

    # Seek to the beginning of the reader.
    var position = reader.seek(0, io.SEEK_START)
    test.assert_equal(position, 0)

    # Read the first byte from the reader.
    buffer = Bytes()
    var byte = reader.read_byte()
    test.assert_equal(byte, 72)

    # Unread the first byte from the reader. Remaining bytes to be read should be the same as the length of the example string.
    reader.unread_byte()
    test.assert_equal(len(reader), len(example))

    # Write from the string reader to a StringBuilder.
    var builder = StringBuilder()
    _ = reader.write_to(builder)
    test.assert_equal(str(builder), example)


fn main() raises:
    test_string_builder()
    test_string_reader()
