from tests.wrapper import MojoTest
from gojo.bytes import reader, buffer
import gojo.io


fn test_read() raises:
    var test = MojoTest("Testing bytes.Reader.read")
    var reader = reader.new_reader("0123456789")
    var dest = List[UInt8](capacity=16)
    _ = reader.read(dest)
    dest.append(0)
    test.assert_equal(String(dest), "0123456789")

    # Test negative seek
    alias NEGATIVE_POSITION_ERROR = "bytes.Reader.seek: negative position"
    var position: Int
    var err: Error
    position, err = reader.seek(-1, io.SEEK_START)

    if not err:
        raise Error("Expected error not raised while testing negative seek.")

    if str(err) != NEGATIVE_POSITION_ERROR:
        raise err

    test.assert_equal(str(err), NEGATIVE_POSITION_ERROR)


fn test_read_after_big_seek() raises:
    var test = MojoTest("Testing bytes.Reader.read after big seek")
    var reader = reader.new_reader("0123456789")
    _ = reader.seek(123456789, io.SEEK_START)
    var dest = List[UInt8](capacity=16)

    var bytes_read: Int
    var err: Error
    bytes_read, err = reader.read(dest)
    if not err:
        raise Error("Expected error not raised while testing big seek.")

    if str(err) != str(io.EOF):
        raise err

    test.assert_equal(str(err), str(io.EOF))


fn test_read_at() raises:
    var test = MojoTest("Testing bytes.Reader.read_at")
    var reader = reader.new_reader("0123456789")

    var dest = List[UInt8](capacity=16)
    var pos = reader.read_at(dest, 0)
    dest.append(0)
    test.assert_equal(String(dest), "0123456789")

    dest = List[UInt8](capacity=16)
    pos = reader.read_at(dest, 1)
    dest.append(0)
    test.assert_equal(String(dest), "123456789")


fn test_seek() raises:
    var test = MojoTest("Testing bytes.Reader.seek")
    var reader = reader.new_reader("0123456789")
    var pos = reader.seek(5, io.SEEK_START)

    var dest = List[UInt8](capacity=16)
    _ = reader.read(dest)
    dest.append(0)
    test.assert_equal(String(dest), "56789")

    # Test SEEK_END relative seek
    pos = reader.seek(-2, io.SEEK_END)
    dest = List[UInt8](capacity=16)
    _ = reader.read(dest)
    dest.append(0)
    test.assert_equal(String(dest), "89")

    # Test SEEK_CURRENT relative seek (should be at the end of the reader, ie [:-4])
    pos = reader.seek(-4, io.SEEK_CURRENT)
    dest = List[UInt8](capacity=16)
    _ = reader.read(dest)
    dest.append(0)
    test.assert_equal(String(dest), "6789")


fn test_read_all() raises:
    var test = MojoTest("Testing io.read_all with bytes.Reader")
    var reader = reader.new_reader("0123456789")
    var result = io.read_all(reader)
    var bytes = result[0]
    bytes.append(0)
    test.assert_equal(String(bytes), "0123456789")


# fn test_write_to() raises:
#     var test = MojoTest("Testing bytes.Reader.write_to")

#     # Create a new reader containing the content "0123456789"
#     var reader = reader.new_reader("0123456789")

#     # Create a new writer containing the content "Hello World"
#     var test_string: String = "Hello World"
#     var w = buffer.new_buffer(test_string)

#     # Write the content of the reader to the writer
#     _ = reader.write_to(w)

#     # Check if the content of the writer is "Hello World0123456789"
#     test.assert_equal(str(w), String("Hello World0123456789"))


fn test_read_and_unread_byte() raises:
    var test = MojoTest("Testing bytes.Reader.read_byte and bytes.Reader.unread_byte")
    var reader = reader.new_reader("0123456789")

    # Read the first byte from the reader.
    var byte: UInt8
    var err: Error
    byte, err = reader.read_byte()
    test.assert_equal(int(byte), 48)
    var post_read_position = reader.index

    # Unread the first byte from the reader. Read position should be moved back by 1
    err = reader.unread_byte()
    if err:
        raise err
    test.assert_equal(int(reader.index), int(post_read_position - 1))


fn test_unread_byte_at_beginning() raises:
    var test = MojoTest("Testing bytes.Reader.unread_byte before reading any bytes")
    var reader = reader.new_reader("0123456789")

    alias AT_BEGINNING_ERROR = "bytes.Reader.unread_byte: at beginning of slice"

    var err = reader.unread_byte()
    if str(err) != AT_BEGINNING_ERROR:
        raise err

    test.assert_equal(str(err), AT_BEGINNING_ERROR)


fn main() raises:
    test_read()
    test_read_after_big_seek()
    test_read_at()
    test_read_all()
    test_read_and_unread_byte()
    test_unread_byte_at_beginning()
    test_seek()
    # test_write_to()
