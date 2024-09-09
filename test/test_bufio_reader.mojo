import gojo.bytes
import gojo.bufio
import gojo.io
from gojo.builtins.bytes import to_string
from gojo.strings import StringBuilder
import testing


def test_read():
    # Create a reader from a string buffer
    var reader = bufio.Reader(bytes.Buffer("Hello"))

    # Read the buffer into and then add more to it.
    var dest = List[UInt8, True](capacity=256)
    _ = reader.read(dest)
    dest.extend(String(" World!").as_bytes())

    testing.assert_equal(to_string(dest), "Hello World!")


def test_read_all():
    var reader = bufio.Reader(bytes.Reader("0123456789"))
    var result = io.read_all(reader)
    testing.assert_equal(to_string(result[0]), "0123456789")


def test_write_to():
    var reader = bufio.Reader(bytes.Buffer("0123456789"))

    # Create a new writer containing the content "Hello World"
    var writer = bytes.Buffer("Hello World")

    # Write the content of the reader to the writer
    _ = reader.write_to(writer)

    # Check if the content of the writer is "Hello World0123456789"
    testing.assert_equal(str(writer), "Hello World0123456789")


def test_read_and_unread_byte():
    # Read the first byte from the reader.
    var reader = bufio.Reader(bytes.Buffer("Hello, World!"))
    var result = reader.read_byte()
    testing.assert_equal(int(result[0]), int(72))
    var post_read_position = reader.read_pos

    # Unread the first byte from the reader. Read position should be moved back by 1
    _ = reader.unread_byte()
    testing.assert_equal(reader.read_pos, post_read_position - 1)


def test_read_slice():
    var reader = bufio.Reader(bytes.Buffer("0123456789"))
    var result = reader.read_slice(ord("5"))
    print(result[0][0])
    testing.assert_equal(to_string(result[0]), "012345")


def test_read_bytes():
    var reader = bufio.Reader(bytes.Buffer("01234\n56789"))
    var result = reader.read_bytes(ord("\n"))
    testing.assert_equal(to_string(result[0]), "01234\n")


def test_read_line():
    var reader = bufio.Reader(bytes.Buffer("01234\n56789"))
    var line: List[UInt8, True]
    var b: Bool
    line, b = reader.read_line()
    testing.assert_equal(to_string(line), "01234")


def test_peek():
    var reader = bufio.Reader(bytes.Buffer("01234\n56789"))

    # Peek doesn't advance the reader, so we should see the same content twice.
    var result = reader.peek(5)
    testing.assert_equal(to_string(result[0]), "01234")
    var second_result = reader.peek(5)
    testing.assert_equal(to_string(second_result[0]), "01234")


def test_discard():
    var reader = bufio.Reader(bytes.Buffer("0123456789"))
    var result = reader.discard(5)
    testing.assert_equal(result[0], 5)

    # Peek doesn't advance the reader, so we should see the same content twice.
    var second_result = reader.peek(5)
    testing.assert_equal(to_string(second_result[0]), "56789")


def main():
    test_read_slice()
