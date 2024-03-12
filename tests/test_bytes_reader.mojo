from tests.wrapper import MojoTest
from gojo.builtins._bytes import Bytes
from gojo.bytes import reader, buffer
import gojo.io


fn test_read() raises:
    var test = MojoTest("Testing bytes.Reader.read")
    var r = reader.new_reader(Bytes("0123456789"))
    var b = Bytes(128)
    _ = r.read(b)
    test.assert_equal(str(b), "0123456789")


fn test_read_at() raises:
    var test = MojoTest("Testing bytes.Reader.read_at")
    var r = reader.new_reader(Bytes("0123456789"))

    var b = Bytes(128)
    var pos = r.read_at(b, 0)
    test.assert_equal(str(b), "0123456789")

    b = Bytes(128)
    pos = r.read_at(b, 1)
    test.assert_equal(str(b), "123456789")


fn test_seek() raises:
    var test = MojoTest("Testing bytes.Reader.seek")
    var r = reader.new_reader(Bytes("0123456789"))
    var pos = r.seek(5, io.SEEK_START)

    var b = Bytes(128)
    _ = r.read(b)
    test.assert_equal(str(b), "56789")


fn test_read_all() raises:
    var test = MojoTest("Testing io.read_all with bytes.Reader")
    var r = reader.new_reader(Bytes("0123456789"))
    var result = io.read_all(r)
    test.assert_equal(str(result), "0123456789")


fn test_write_to() raises:
    var test = MojoTest("Testing bytes.Reader.write_to")

    # Create a new reader containing the content "0123456789"
    var r = reader.new_reader(Bytes("0123456789"))

    # Create a new writer containing the content "Hello World"
    var test_string: String = "Hello World"
    var w = buffer.new_buffer(test_string)

    # Write the content of the reader to the writer
    _ = r.write_to(w)

    # Check if the content of the writer is "Hello World0123456789"
    test.assert_equal(str(w), String("Hello World0123456789"))


fn test_read_and_unread_byte() raises:
    var test = MojoTest("Testing bytes.Reader.read_byte and bytes.Reader.unread_byte")
    var s: String = "0123456789"
    var reader = reader.new_reader(s)

    # Read the first byte from the reader.
    var buffer = Bytes(128)
    var byte = reader.read_byte()
    test.assert_equal(byte, 48)
    var post_read_position = reader.index

    # Unread the first byte from the reader. Read position should be moved back by 1
    reader.unread_byte()
    test.assert_equal(reader.index, post_read_position - 1)



fn main() raises:
    test_read()
    test_read_at()
    test_read_all()
    test_read_and_unread_byte()
    test_seek()
    test_write_to()
