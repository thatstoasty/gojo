import gojo.bytes
import gojo.bufio
import gojo.io
from gojo.bytes import to_string
from gojo.strings import StringBuilder
import testing


def test_read():
    # Create a reader from a string buffer
    reader = bufio.Reader(bytes.Buffer("Hello"))

    # Read the buffer into and then add more to it.
    dest = List[UInt8, True](capacity=16)
    _ = reader.read(dest)
    dest.extend(String(" World!").as_bytes())

    testing.assert_equal(to_string(dest), "Hello World!")


def test_read_all():
    reader = bufio.Reader(bytes.Reader("0123456789"))
    testing.assert_equal(to_string(io.read_all(reader)), "0123456789")


# def test_write_to():
#     reader = bufio.Reader(bytes.Buffer("0123456789"))

#     # Create a new writer containing the content "Hello World"
#     writer = bytes.Buffer("Hello World")

#     # Write the content of the reader to the writer
#     _ = reader.write_to(writer)

#     # Check if the content of the writer is "Hello World0123456789"
#     testing.assert_equal(str(writer), "Hello World0123456789")


def test_read_and_unread_byte():
    # Read the first byte from the reader.
    reader = bufio.Reader(bytes.Buffer("Hello, World!"))
    testing.assert_equal(reader.read_byte(), 72)
    post_read_position = reader.read_pos

    # Unread the first byte from the reader. Read position should be moved back by 1
    reader.unread_byte()
    testing.assert_equal(reader.read_pos, post_read_position - 1)


def test_read_bytes():
    reader = bufio.Reader(bytes.Buffer("0123456789"))
    testing.assert_equal(to_string(reader.read_bytes(ord("5"))), "012345")


def test_read_line():
    reader = bufio.Reader(bytes.Buffer("01234\n56789"))
    testing.assert_equal(to_string(reader.read_line()), "01234")


def test_peek():
    reader = bufio.Reader(bytes.Buffer("01234\n56789"))

    # Peek doesn't advance the reader, so we should see the same content twice.
    testing.assert_equal(to_string(reader.peek(5)), "01234")
    testing.assert_equal(to_string(reader.peek(5)), "01234")


def test_discard():
    reader = bufio.Reader(bytes.Buffer("0123456789"))
    testing.assert_equal(reader.discard(5), 5)
    testing.assert_equal(to_string(reader.peek(5)), "56789")
