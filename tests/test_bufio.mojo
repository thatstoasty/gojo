from tests.wrapper import MojoTest
from gojo.bytes import buffer
from gojo.builtins.bytes import to_string
from gojo.bufio import Reader, Scanner, scan_words, scan_bytes, Writer
from gojo.io import read_all, FileWrapper
from gojo.strings import StringBuilder


fn test_read():
    var test = MojoTest("Testing bufio.Reader.read")

    # Create a reader from a string buffer
    var s: String = "Hello"
    var buf = buffer.new_buffer(s)
    var reader = Reader(buf^)

    # Read the buffer into List[UInt8] and then add more to List[UInt8]
    var dest = List[UInt8](capacity=256)
    _ = reader.read(dest)
    dest.extend(String(" World!").as_bytes())

    test.assert_equal(to_string(dest), "Hello World!")


fn test_read_all():
    var test = MojoTest("Testing bufio.Reader with io.read_all")

    var s: String = "0123456789"
    var buf = buffer.new_reader(s)
    var reader = Reader(buf^)
    var result = read_all(reader)
    var bytes = result[0]
    bytes.append(0)
    test.assert_equal(String(bytes), "0123456789")


fn test_write_to():
    var test = MojoTest("Testing bufio.Reader.write_to")

    var buf = buffer.new_buffer("0123456789")
    var reader = Reader(buf^)

    # Create a new writer containing the content "Hello World"
    var writer = buffer.new_buffer("Hello World")

    # Write the content of the reader to the writer
    _ = reader.write_to(writer)

    # Check if the content of the writer is "Hello World0123456789"
    test.assert_equal(str(writer), "Hello World0123456789")


fn test_read_and_unread_byte():
    var test = MojoTest("Testing bufio.Reader.read_byte and bufio.Reader.unread_byte")

    # Read the first byte from the reader.
    var example: String = "Hello, World!"
    var buf = buffer.new_buffer(example^)
    var reader = Reader(buf^)
    var result = reader.read_byte()
    test.assert_equal(int(result[0]), int(72))
    var post_read_position = reader.read_pos

    # Unread the first byte from the reader. Read position should be moved back by 1
    _ = reader.unread_byte()
    test.assert_equal(reader.read_pos, post_read_position - 1)


fn test_read_slice():
    var test = MojoTest("Testing bufio.Reader.read_slice")
    var buf = buffer.new_buffer("0123456789")
    var reader = Reader(buf^)

    var result = reader.read_slice(ord("5"))
    test.assert_equal(to_string(result[0]), "012345")


fn test_read_bytes():
    var test = MojoTest("Testing bufio.Reader.read_bytes")
    var buf = buffer.new_buffer("01234\n56789")
    var reader = Reader(buf^)

    var result = reader.read_bytes(ord("\n"))
    test.assert_equal(to_string(result[0]), "01234")


fn test_read_line():
    var test = MojoTest("Testing bufio.Reader.read_line")
    var buf = buffer.new_buffer("01234\n56789")
    var reader = Reader(buf^)

    var line: List[UInt8]
    var b: Bool
    line, b = reader.read_line()
    test.assert_equal(String(line), "01234")


fn test_peek():
    var test = MojoTest("Testing bufio.Reader.peek")
    var buf = buffer.new_buffer("01234\n56789")
    var reader = Reader(buf^)

    # Peek doesn't advance the reader, so we should see the same content twice.
    var result = reader.peek(5)
    var second_result = reader.peek(5)
    test.assert_equal(to_string(result[0]), "01234")
    test.assert_equal(to_string(second_result[0]), "01234")


fn test_discard():
    var test = MojoTest("Testing bufio.Reader.discard")
    var buf = buffer.new_buffer("0123456789")
    var reader = Reader(buf^)

    var result = reader.discard(5)
    test.assert_equal(result[0], 5)

    # Peek doesn't advance the reader, so we should see the same content twice.
    var second_result = reader.peek(5)
    test.assert_equal(to_string(second_result[0]), "56789")


fn test_write():
    var test = MojoTest("Testing bufio.Writer.write and flush")

    # Create a new List[UInt8] Buffer Writer and use it to create the buffered Writer
    var buf = buffer.new_buffer()
    var writer = Writer(buf^)

    # Write the content from src to the buffered writer's internal buffer and flush it to the List[UInt8] Buffer Writer.
    var src = String("0123456789").as_bytes()
    var result = writer.write(src)
    _ = writer.flush()

    test.assert_equal(result[0], 10)
    test.assert_equal(str(writer.writer), "0123456789")


fn test_several_writes():
    var test = MojoTest("Testing several bufio.Writer.write")

    # Create a new List[UInt8] Buffer Writer and use it to create the buffered Writer
    var buf = buffer.new_buffer()
    var writer = Writer(buf^)

    # Write the content from src to the buffered writer's internal buffer and flush it to the List[UInt8] Buffer Writer.
    var src = String("0123456789").as_bytes()
    for _ in range(100):
        _ = writer.write(src)
    _ = writer.flush()

    test.assert_equal(len(writer.writer), 1000)
    var text = str(writer.writer)
    test.assert_equal(text[0], "0")
    test.assert_equal(text[999], "9")


fn test_big_write():
    var test = MojoTest("Testing a big bufio.Writer.write")

    # Create a new List[UInt8] Buffer Writer and use it to create the buffered Writer
    var buf = buffer.new_buffer()
    var writer = Writer(buf^)

    # Build a string larger than the size of the Bufio struct's internal buffer.
    var builder = StringBuilder(capacity=5000)
    for _ in range(500):
        _ = builder.write_string("0123456789")

    # When writing, it should bypass the Bufio struct's buffer and write directly to the underlying bytes buffer writer. So, no need to flush.
    var text = str(builder)
    _ = writer.write(text.as_bytes())
    test.assert_equal(len(writer.writer), 5000)
    test.assert_equal(text[0], "0")
    test.assert_equal(text[4999], "9")


fn test_write_byte():
    var test = MojoTest("Testing bufio.Writer.write_byte")

    # Create a new List[UInt8] Buffer Writer and use it to create the buffered Writer
    var buf = buffer.new_buffer("Hello")
    var writer = Writer(buf^)

    # Write a byte with the value of 32 to the writer's internal buffer and flush it to the List[UInt8] Buffer Writer.
    var result = writer.write_byte(32)
    _ = writer.flush()

    test.assert_equal(result[0], 1)
    test.assert_equal(str(writer.writer), "Hello ")


fn test_write_string():
    var test = MojoTest("Testing bufio.Writer.write_string")

    # Create a new List[UInt8] Buffer Writer and use it to create the buffered Writer
    var buf = buffer.new_buffer("Hello")
    var writer = Writer(buf^)

    # Write a string to the writer's internal buffer and flush it to the List[UInt8] Buffer Writer.
    var result = writer.write_string(" World!")
    _ = writer.flush()

    test.assert_equal(result[0], 7)
    test.assert_equal(str(writer.writer), "Hello World!")


fn test_read_from():
    var test = MojoTest("Testing bufio.Writer.read_from")

    # Create a new List[UInt8] Buffer Writer and use it to create the buffered Writer
    var buf = buffer.new_buffer("Hello")
    var writer = Writer(buf^)

    # Read from a ReaderFrom struct into the Buffered Writer's internal buffer and flush it to the List[UInt8] Buffer Writer.
    var src = String(" World!").as_bytes()
    var reader_from = buffer.new_buffer(src)
    var result = writer.read_from(reader_from)
    _ = writer.flush()

    test.assert_equal(int(result[0]), 7)
    test.assert_equal(str(writer.writer), "Hello World!")


# TODO: Add big file read/write to make sure buffer usage is correct
fn main():
    test_read()
    test_read_all()
    test_write_to()
    test_read_and_unread_byte()
    test_read_slice()
    test_peek()
    test_discard()
    test_write()
    test_several_writes()
    test_big_write()
    test_write_byte()
    test_write_string()
    test_read_from()
