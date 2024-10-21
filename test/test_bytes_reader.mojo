import gojo.bytes
import gojo.io
from gojo.bytes import to_string
import testing


def test_read():
    reader = bytes.Reader("0123456789")
    dest = List[UInt8, True](capacity=16)
    _ = reader.read(dest)
    testing.assert_equal(to_string(dest), "0123456789")

    # Test negative seek
    alias NEGATIVE_POSITION_ERROR = "bytes.Reader.seek: negative position"

    try:
        position = reader.seek(-1, io.SEEK_START)
        raise Error("Expected error not raised while testing negative seek.")
    except e:
        testing.assert_equal(str(e), NEGATIVE_POSITION_ERROR)


def test_read_after_big_seek():
    reader = bytes.Reader("0123456789")
    _ = reader.seek(123456789, io.SEEK_START)
    dest = List[UInt8, True](capacity=16)

    try:
        _ = reader.read(dest)
        raise Error("Expected error not raised while testing big seek.")
    except e:
        testing.assert_equal(str(e), io.EOF)


def test_read_at():
    reader = bytes.Reader("0123456789")

    dest = List[UInt8, True](capacity=16)
    pos = reader.read_at(dest, 0)
    testing.assert_equal(to_string(dest), "0123456789")

    dest = List[UInt8, True](capacity=16)
    pos = reader.read_at(dest, 1)
    testing.assert_equal(to_string(dest), "123456789")


def test_seek():
    reader = bytes.Reader("0123456789")
    pos = reader.seek(5, io.SEEK_START)

    dest = List[UInt8, True](capacity=16)
    _ = reader.read(dest)
    testing.assert_equal(to_string(dest), "56789")

    # Test SEEK_END relative seek
    pos = reader.seek(-2, io.SEEK_END)
    dest = List[UInt8, True](capacity=16)
    _ = reader.read(dest)
    testing.assert_equal(to_string(dest), "89")

    # Test SEEK_CURRENT relative seek (should be at the end of the reader, ie [:-4])
    pos = reader.seek(-4, io.SEEK_CURRENT)
    dest = List[UInt8, True](capacity=16)
    _ = reader.read(dest)
    testing.assert_equal(to_string(dest), "6789")


def test_write_to():
    # Create a new reader containing the content "0123456789"
    reader = bytes.Reader("0123456789")

    # Create a new writer containing the content "Hello World"
    w = bytes.Buffer("Hello World")

    # Write the content of the reader to the writer
    _ = reader.write_to(w)

    # Check if the content of the writer is "Hello World0123456789"
    testing.assert_equal(str(w), String("Hello World0123456789"))


def test_read_and_unread_byte():
    reader = bytes.Reader("0123456789")

    # Read the first byte from the reader.
    byte = reader.read_byte()
    testing.assert_equal(int(byte), 48)
    post_read_position = reader.index

    # Unread the first byte from the reader. Read position should be moved back by 1
    reader.unread_byte()
    testing.assert_equal(int(reader.index), int(post_read_position - 1))


def test_unread_byte_at_beginning():
    reader = bytes.Reader("0123456789")

    alias AT_BEGINNING_ERROR = "bytes.Reader.unread_byte: at beginning of buffer."

    try:
        _ = reader.unread_byte()
    except e:
        testing.assert_equal(str(e), AT_BEGINNING_ERROR)
