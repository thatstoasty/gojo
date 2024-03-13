from tests.wrapper import MojoTest
from gojo.builtins._bytes import Bytes
from gojo.bytes import reader, buffer
import gojo.io


fn test_read() raises:
    var test = MojoTest("Testing bytes.Reader.read")
    var reader = reader.new_reader(Bytes("0123456789"))
    var dest = Bytes(128)
    _ = reader.read(dest)
    test.assert_equal(str(dest), "0123456789")

    # Test negative seek
    alias NEGATIVE_POSITION_ERROR = "bytes.Reader.seek: negative position"
    var result = reader.seek(-1, io.SEEK_START)

    if not result.has_error():
        raise Error("Expected error not raised while testing negative seek.")

    var error = result.get_error()
    if str(error) != NEGATIVE_POSITION_ERROR:
        raise error.error

    test.assert_equal(str(error), NEGATIVE_POSITION_ERROR)
    


fn test_read_after_big_seek() raises:
    var test = MojoTest("Testing bytes.Reader.read after big seek")
    var reader = reader.new_reader(Bytes("0123456789"))
    _ = reader.seek(123456789, io.SEEK_START)
    var dest = Bytes(128)

    var result = reader.read(dest)
    if not result.has_error():
        raise Error("Expected error not raised while testing negative seek.")
    
    var error = result.get_error()
    if str(error) != io.EOF:
        raise error.error

    test.assert_equal(str(error), io.EOF)


fn test_read_at() raises:
    var test = MojoTest("Testing bytes.Reader.read_at")
    var reader = reader.new_reader(Bytes("0123456789"))

    var dest = Bytes(128)
    var pos = reader.read_at(dest, 0)
    test.assert_equal(str(dest), "0123456789")

    dest = Bytes(128)
    pos = reader.read_at(dest, 1)
    test.assert_equal(str(dest), "123456789")


fn test_seek() raises:
    var test = MojoTest("Testing bytes.Reader.seek")
    var reader = reader.new_reader(Bytes("0123456789"))
    var pos = reader.seek(5, io.SEEK_START)

    var dest = Bytes(16)
    _ = reader.read(dest)
    test.assert_equal(str(dest), "56789")

    # Test SEEK_END relative seek
    pos = reader.seek(-2, io.SEEK_END)
    dest = Bytes(16)
    _ = reader.read(dest)
    test.assert_equal(str(dest), "89")

    # Test SEEK_CURRENT relative seek (should be at the end of the reader, ie [:-4])
    pos = reader.seek(-4, io.SEEK_CURRENT)
    dest = Bytes(16)
    _ = reader.read(dest)
    test.assert_equal(str(dest), "6789")


fn test_read_all() raises:
    var test = MojoTest("Testing io.read_all with bytes.Reader")
    var reader = reader.new_reader(Bytes("0123456789"))
    var result = io.read_all(reader)
    test.assert_equal(str(result), "0123456789")


fn test_write_to() raises:
    var test = MojoTest("Testing bytes.Reader.write_to")

    # Create a new reader containing the content "0123456789"
    var reader = reader.new_reader(Bytes("0123456789"))

    # Create a new writer containing the content "Hello World"
    var test_string: String = "Hello World"
    var w = buffer.new_buffer(test_string)

    # Write the content of the reader to the writer
    _ = reader.write_to(w)

    # Check if the content of the writer is "Hello World0123456789"
    test.assert_equal(str(w), String("Hello World0123456789"))


fn test_read_and_unread_byte() raises:
    var test = MojoTest("Testing bytes.Reader.read_byte and bytes.Reader.unread_byte")
    var s: String = "0123456789"
    var reader = reader.new_reader(s)

    # Read the first byte from the reader.
    var buffer = Bytes(128)
    var result = reader.read_byte()
    test.assert_equal(result.get_value(), 48)
    var post_read_position = reader.index

    # Unread the first byte from the reader. Read position should be moved back by 1
    result = reader.unread_byte()
    if result.has_error():
        raise result.get_error().error
    test.assert_equal(reader.index, post_read_position - 1)


fn test_unread_byte_at_beginning() raises:
    var test = MojoTest("Testing bytes.Reader.read_byte and bytes.Reader.unread_byte")
    var s: String = "0123456789"
    var reader = reader.new_reader(s)

    alias AT_BEGINNING_ERROR = "bytes.Reader.unread_byte: at beginning of slice"

    var error = reader.unread_byte()
    if str(error.value()) != AT_BEGINNING_ERROR:
        raise error.value().error
    
    test.assert_equal(str(error.value()), AT_BEGINNING_ERROR)


fn main() raises:
    test_read()
    test_read_after_big_seek()
    test_read_at()
    test_read_all()
    test_read_and_unread_byte()
    test_unread_byte_at_beginning()
    test_seek()
    test_write_to()
