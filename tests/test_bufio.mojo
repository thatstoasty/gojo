from tests.wrapper import MojoTest
import gojo.bytes
import gojo.bufio
import gojo.io
from gojo.builtins.bytes import to_string
from gojo.strings import StringBuilder


fn test_read():
    var test = MojoTest("Testing bufio.Reader.read")

    # Create a reader from a string buffer
    var s: String = "Hello"
    var buf = bytes.Buffer(buf=s.as_bytes())
    var reader = bufio.Reader(buf^)

    # Read the buffer into and then add more to it.
    var dest = List[UInt8, True](capacity=256)
    _ = reader.read(dest)
    dest.extend(String(" World!").as_bytes())

    test.assert_equal(to_string(dest), "Hello World!")


fn test_read_all():
    var test = MojoTest("Testing bufio.Reader with io.read_all")

    var s: String = "0123456789"
    var reader = bufio.Reader(bytes.Reader(s.as_bytes()))
    var result = io.read_all(reader)
    test.assert_equal(to_string(result[0]), "0123456789")


fn test_write_to():
    var test = MojoTest("Testing bufio.Reader.write_to")

    var reader = bufio.Reader(bytes.Buffer("0123456789"))

    # Create a new writer containing the content "Hello World"
    var writer = bytes.Buffer("Hello World")

    # Write the content of the reader to the writer
    _ = reader.write_to(writer)

    # Check if the content of the writer is "Hello World0123456789"
    test.assert_equal(str(writer), "Hello World0123456789")


fn test_read_and_unread_byte():
    var test = MojoTest("Testing bufio.Reader.read_byte and bufio.Reader.unread_byte")

    # Read the first byte from the reader.
    var example: String = "Hello, World!"
    var buf = bytes.Buffer(buf=example.as_bytes())
    var reader = bufio.Reader(buf^)
    var result = reader.read_byte()
    test.assert_equal(int(result[0]), int(72))
    var post_read_position = reader.read_pos

    # Unread the first byte from the reader. Read position should be moved back by 1
    _ = reader.unread_byte()
    test.assert_equal(reader.read_pos, post_read_position - 1)


fn test_read_slice():
    var test = MojoTest("Testing bufio.Reader.read_slice")
    var buf = bytes.Buffer(buf=String("0123456789").as_bytes())
    var reader = bufio.Reader(buf^)

    var result = reader.read_slice(ord("5"))
    test.assert_equal(to_string(result[0]), "012345")


fn test_read_bytes():
    var test = MojoTest("Testing bufio.Reader.read_bytes")
    var buf = bytes.Buffer(buf=String("01234\n56789").as_bytes())
    var reader = bufio.Reader(buf^)

    var result = reader.read_bytes(ord("\n"))
    test.assert_equal(to_string(result[0]), "01234")


fn test_read_line():
    var test = MojoTest("Testing bufio.Reader.read_line")
    var buf = bytes.Buffer(buf=String("01234\n56789").as_bytes())
    var reader = bufio.Reader(buf^)

    var line: List[UInt8, True]
    var b: Bool
    line, b = reader.read_line()
    test.assert_equal(String(line), "01234")


fn test_peek():
    var test = MojoTest("Testing bufio.Reader.peek")
    var buf = bytes.Buffer(buf=String("01234\n56789").as_bytes())
    var reader = bufio.Reader(buf^)

    # Peek doesn't advance the reader, so we should see the same content twice.
    var result = reader.peek(5)
    var second_result = reader.peek(5)
    test.assert_equal(to_string(result[0]), "01234")
    test.assert_equal(to_string(second_result[0]), "01234")


fn test_discard():
    var test = MojoTest("Testing bufio.Reader.discard")
    var buf = bytes.Buffer(buf=String("0123456789").as_bytes())
    var reader = bufio.Reader(buf^)

    var result = reader.discard(5)
    test.assert_equal(result[0], 5)

    # Peek doesn't advance the reader, so we should see the same content twice.
    var second_result = reader.peek(5)
    test.assert_equal(to_string(second_result[0]), "56789")


fn test_write():
    var test = MojoTest("Testing bufio.Writer.write and flush")

    # Create a new Buffer Writer and use it to create the buffered Writer
    var writer = bufio.Writer(bytes.Buffer())

    # Write the content from src to the buffered writer's internal buffer and flush it to the Buffer Writer.
    var src = String("0123456789").as_bytes_slice()
    var result = writer.write(src)
    _ = writer.flush()

    test.assert_equal(result[0], 10)
    test.assert_equal(str(writer.writer), "0123456789")


fn test_several_writes():
    var test = MojoTest("Testing several bufio.Writer.write")

    # Create a new Buffer Writer and use it to create the buffered Writer
    var buf = bytes.Buffer(capacity=1100)
    var writer = bufio.Writer(buf^)

    # Write the content from src to the buffered writer's internal buffer and flush it to the Buffer Writer.
    var src = String("0123456789")
    for _ in range(100):
        _ = writer.write_string(src)
    _ = writer.flush()

    test.assert_equal(len(writer.writer), 1000)
    var text = str(writer.writer)
    test.assert_equal(text[0], "0")
    test.assert_equal(text[999], "9")


fn test_several_writes_small_buffer():
    var test = MojoTest("Testing several bufio.Writer.write into small buffer")

    # Create a new Buffer Writer and use it to create the buffered Writer
    var buf = bytes.Buffer(capacity=1000)
    var writer = bufio.Writer(buf^, capacity=16)

    # Write the content from src to the buffered writer's internal buffer and flush it to the Buffer Writer.
    var src = String("0123456789")
    for _ in range(100):
        _ = writer.write_string(src)
    _ = writer.flush()

    test.assert_equal(len(writer.writer), 1000)
    var text = str(writer.writer)
    test.assert_equal(text[0], "0")
    test.assert_equal(text[999], "9")


fn test_big_write():
    var test = MojoTest("Testing a big bufio.Writer.write")

    # Create a new Buffer Writer and use it to create the buffered Writer
    var buf = bytes.Buffer()
    var writer = bufio.Writer(buf^)

    # Build a string larger than the size of the Bufio struct's internal buffer.
    var builder = StringBuilder(capacity=5000)
    for _ in range(500):
        _ = builder.write_string("0123456789")

    # When writing, it should bypass the Bufio struct's buffer and write directly to the underlying bytes buffer writer. So, no need to flush.
    var text = str(builder)
    _ = writer.write(text.as_bytes_slice())
    test.assert_equal(len(writer.writer), 5000)
    test.assert_equal(text[0], "0")
    test.assert_equal(text[4999], "9")


fn test_write_byte():
    var test = MojoTest("Testing bufio.Writer.write_byte")

    # Create a new Buffer Writer and use it to create the buffered Writer
    var buf = bytes.Buffer(buf=String("Hello").as_bytes())
    var writer = bufio.Writer(buf^)

    # Write a byte with the value of 32 to the writer's internal buffer and flush it to the Buffer Writer.
    var result = writer.write_byte(32)
    _ = writer.flush()

    test.assert_equal(result[0], 1)
    test.assert_equal(str(writer.writer), "Hello ")


fn test_write_string():
    var test = MojoTest("Testing bufio.Writer.write_string")

    # Create a new Buffer Writer and use it to create the buffered Writer
    var buf = bytes.Buffer(buf=String("Hello").as_bytes())
    var writer = bufio.Writer(buf^)

    # Write a string to the writer's internal buffer and flush it to the Buffer Writer.
    var result = writer.write_string(" World!")
    _ = writer.flush()

    test.assert_equal(result[0], 7)
    test.assert_equal(str(writer.writer), "Hello World!")


fn test_read_from():
    var test = MojoTest("Testing bufio.Writer.read_from")

    # Create a new Buffer Writer and use it to create the buffered Writer
    var writer = bufio.Writer(bytes.Buffer("Hello"))

    # Read from a ReaderFrom struct into the Buffered Writer's internal buffer and flush it to the Buffer Writer.
    var reader_from = bytes.Buffer(" World!")
    var result = writer.read_from(reader_from)
    _ = writer.flush()

    test.assert_equal(int(result[0]), 7)
    test.assert_equal(str(writer.writer), "Hello World!")


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
    test_several_writes_small_buffer()
    test_big_write()
    test_write_byte()
    test_write_string()
    test_read_from()  # This test is failing with OOB
