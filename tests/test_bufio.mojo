from tests.wrapper import MojoTest
from gojo.bytes import buffer
from gojo.builtins import Bytes, Result, WrappedError
from gojo.bufio import Reader, Scanner, scan_words, scan_bytes, Writer
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
    test.assert_equal(str(result.unwrap()), "0123456789")


fn test_write_to() raises:
    var test = MojoTest("Testing bufio.Reader.write_to")

    var buf = buffer.new_buffer("0123456789")
    var reader = Reader(buf)

    # Create a new writer containing the content "Hello World"
    var writer = buffer.new_buffer("Hello World")

    # Write the content of the reader to the writer
    _ = reader.write_to(writer)

    # Check if the content of the writer is "Hello World0123456789"
    test.assert_equal(str(writer), "Hello World0123456789")


fn test_read_and_unread_byte() raises:
    var test = MojoTest("Testing bufio.Reader.read_byte and bufio.Reader.unread_byte")

    # Read the first byte from the reader.
    var example: String = "Hello, World!"
    var buf = buffer.new_buffer(example ^)
    var reader = Reader(buf)
    var buffer = Bytes(512)
    var result = reader.read_byte()
    test.assert_equal(result.unwrap(), 72)
    var post_read_position = reader.read_pos

    # Unread the first byte from the reader. Read position should be moved back by 1
    _ = reader.unread_byte()
    test.assert_equal(reader.read_pos, post_read_position - 1)


fn test_read_slice() raises:
    var test = MojoTest("Testing bufio.Reader.read_slice")
    var buf = buffer.new_buffer("0123456789")
    var reader = Reader(buf)

    var result = reader.read_slice(ord(5))
    test.assert_equal(result.unwrap(), "012345")


fn test_read_bytes() raises:
    var test = MojoTest("Testing bufio.Reader.read_bytes")
    var buf = buffer.new_buffer("01234\n56789")
    var reader = Reader(buf)

    var result = reader.read_bytes(ord("\n"))
    test.assert_equal(result.unwrap(), "01234")


# TODO: read_line is broken until Mojo support unpacking Memory only types from return Tuples.
fn test_read_line() raises:
    var test = MojoTest("Testing bufio.Reader.read_line")
    # var buf = buffer.new_buffer("01234\n56789")
    # var reader = Reader(buf)

    # var line: Bytes
    # var b: Bool
    # line, b = reader.read_line()
    # test.assert_equal(line, "01234")


fn test_peek() raises:
    var test = MojoTest("Testing bufio.Reader.peek")
    var buf = buffer.new_buffer("01234\n56789")
    var reader = Reader(buf)

    # Peek doesn't advance the reader, so we should see the same content twice.
    var result = reader.peek(5)
    var second_result = reader.peek(5)
    test.assert_equal(result.unwrap(), "01234")
    test.assert_equal(second_result.unwrap(), "01234")


fn test_discard() raises:
    var test = MojoTest("Testing bufio.Reader.discard")
    var buf = buffer.new_buffer("0123456789")
    var reader = Reader(buf)

    var result = reader.discard(5)
    test.assert_equal(result.unwrap(), 5)

    # Peek doesn't advance the reader, so we should see the same content twice.
    var second_result = reader.peek(5)
    test.assert_equal(second_result.unwrap(), "56789")


fn test_write() raises:
    var test = MojoTest("Testing bufio.Writer.write and flush")

    # Create a new Bytes Buffer Writer and use it to create the buffered Writer
    var buf = buffer.new_buffer()
    var writer = Writer(buf)

    # Write the content from src to the buffered writer's internal buffer and flush it to the Bytes Buffer Writer.
    var src = Bytes("0123456789")
    var result = writer.write(src)
    _ = writer.flush()

    test.assert_equal(result.unwrap(), 10)
    test.assert_equal(str(writer.writer), "0123456789")


fn test_write_byte() raises:
    var test = MojoTest("Testing bufio.Writer.write_byte")

    # Create a new Bytes Buffer Writer and use it to create the buffered Writer
    var buf = buffer.new_buffer("Hello")
    var writer = Writer(buf)

    # Write a byte with the value of 32 to the writer's internal buffer and flush it to the Bytes Buffer Writer.
    var result = writer.write_byte(32)
    _ = writer.flush()

    test.assert_equal(result.unwrap(), 1)
    test.assert_equal(str(writer.writer), "Hello ")


fn test_write_string() raises:
    var test = MojoTest("Testing bufio.Writer.write_string")

    # Create a new Bytes Buffer Writer and use it to create the buffered Writer
    var buf = buffer.new_buffer("Hello")
    var writer = Writer(buf)

    # Write a string to the writer's internal buffer and flush it to the Bytes Buffer Writer.
    var result = writer.write_string(" World!")
    _ = writer.flush()

    test.assert_equal(result.unwrap(), 7)
    test.assert_equal(str(writer.writer), "Hello World!")


# TODO: Loops for awhile without reading anything. Need to fix.
fn test_read_from() raises:
    var test = MojoTest("Testing bufio.Writer.read_from")

    # Create a new Bytes Buffer Writer and use it to create the buffered Writer
    var buf = buffer.new_buffer("Hello")
    var writer = Writer(buf)

    # Read from a ReaderFrom struct into the Buffered Writer's internal buffer and flush it to the Bytes Buffer Writer.
    var src = Bytes(" World!")
    var reader_from = buffer.new_buffer(src)
    var result = writer.read_from(reader_from)
    _ = writer.flush()

    test.assert_equal(result.unwrap(), 7)
    test.assert_equal(str(writer.writer), "Hello World!")


fn main() raises:
    test_read()
    # test_read_all()
    # test_write_to()
    test_read_and_unread_byte()
    test_read_slice()
    test_peek()
    test_discard()
    test_write()
    test_write_byte()
    test_write_string()
    test_read_from()
