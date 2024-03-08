from tests.wrapper import MojoTest
from gojo.bytes import buffer
from gojo.builtins._bytes import Bytes
from gojo.bufio import Reader, Scanner, scan_words, scan_bytes
from gojo.io import FileWrapper, read_all


fn test_read() raises:
    var test = MojoTest("Testing bufio.Reader.read")

    # Create a reader from a string buffer
    var s: String = "Hello"
    var buf = buffer.new_buffer(s)
    var reader = Reader(buf)

    # Read the buffer into Bytes and then add more to Bytes
    var dest = Bytes(256)
    _ = reader.read(dest)
    dest.extend(" World!")

    test.assert_equal(dest, "Hello World!")


fn test_read_all() raises:
    var test = MojoTest("Testing bufio.Reader with io.read_all")

    var s: String = "0123456789"
    var buf = buffer.new_buffer(s)
    var reader = Reader(buf)
    var result = read_all(reader)
    test.assert_equal(str(result), "0123456789")


# TODO: Failing to write the contents of the reader to the writer
fn test_write_to() raises:
    var test = MojoTest("Testing bufio.Reader.write_to")

    var buf = buffer.new_buffer("0123456789")
    var reader = Reader(buf)

    # Create a new writer containing the content "Hello World"
    var writer = buffer.new_buffer("Hello World")

    # Write the content of the reader to the writer
    _ = reader.write_to(writer)

    # Check if the content of the writer is "Hello World0123456789"
    test.assert_equal(str(writer), String("Hello World0123456789"))


# TODO: Failing with  bufio: tried to fill full buffer even though the buffer size is dynamic
fn test_read_and_unread_byte() raises:
    var test = MojoTest("Testing bufio.Reader.read_byte and bufio.Reader.unread_byte")

    # Read the first byte from the reader.
    var example: String = "Hello, World!"
    var buf = buffer.new_buffer(example ^)
    var reader = Reader(buf)
    var buffer = Bytes()
    var byte = reader.read_byte()
    test.assert_equal(byte, 72)
    var post_read_position = reader.read_pos

    # Unread the first byte from the reader. Read position should be moved back by 1
    reader.unread_byte()
    test.assert_equal(reader.read_pos, post_read_position - 1)


# TODO: Failing with bufio: buffer full, seems like a similar issue with the above.
fn test_read_slice() raises:
    var test = MojoTest("Testing bufio.Reader.read_slice")
    var buf = buffer.new_buffer("0123456789")
    var reader = Reader(buf)

    test.assert_equal(reader.read_slice(5), "01234")


fn test_read_bytes() raises:
    var test = MojoTest("Testing bufio.Reader.read_bytes")
    var buf = buffer.new_buffer("01234\n56789")
    var reader = Reader(buf)

    test.assert_equal(reader.read_bytes(ord("\n")), "01234")


# TODO: read_line is broken until Mojo support unpacking Memory only types from return Tuples.
fn test_read_line() raises:
    var test = MojoTest("Testing bufio.Reader.read_line")
    # var buf = buffer.new_buffer("01234\n56789")
    # var reader = Reader(buf)

    # var line: Bytes
    # var b: Bool
    # line, b = reader.read_line()
    # test.assert_equal(line, "01234")


# TODO: Failing with bufio: buffer full
fn test_peek() raises:
    var test = MojoTest("Testing bufio.Reader.peek")
    var buf = buffer.new_buffer("01234\n56789")
    var reader = Reader(buf)

    var initial_read_position = reader.read_pos
    var inital_write_position = reader.write_pos
    test.assert_equal(reader.peek(5), "01234")
    test.assert_equal(reader.read_pos, initial_read_position)
    test.assert_equal(reader.write_pos, inital_write_position)


fn test_writer():
    var test = MojoTest("Testing bufio.Writer")


fn main() raises:
    test_read()
    test_read_all()
    test_write_to()
    # test_read_and_unread_byte()
    # test_read_slice()
    # test_peek()
