import gojo.bytes
import gojo.bufio
import gojo.io
from gojo.bytes import to_string
from gojo.strings import StringBuilder
import testing


def test_write():
    # Create a new Buffer Writer and use it to create the buffered Writer
    writer = bufio.Writer(bytes.Buffer())

    # Write the content from src to the buffered writer's internal buffer and flush it to the Buffer Writer.
    writer.write("0123456789")
    writer.flush()

    testing.assert_equal(writer.writer.consume(), "0123456789")


def test_several_writes():
    # Create a new Buffer Writer and use it to create the buffered Writer
    writer = bufio.Writer(bytes.Buffer(capacity=1100))

    # Write the content from src to the buffered writer's internal buffer and flush it to the Buffer Writer.
    for _ in range(100):
        writer.write("0123456789")
    writer.flush()

    text = writer.writer.as_string_slice()
    testing.assert_equal(len(text), 1000)
    testing.assert_equal(text[0], "0")
    testing.assert_equal(text[999], "9")


def test_several_writes_small_buffer():
    # Create a new Buffer Writer and use it to create the buffered Writer
    writer = bufio.Writer(bytes.Buffer(capacity=1000), capacity=16)

    # Write the content from src to the buffered writer's internal buffer and flush it to the Buffer Writer.
    for _ in range(100):
        writer.write("0123456789")
    writer.flush()

    text = writer.writer.as_string_slice()
    testing.assert_equal(len(text), 1000)
    testing.assert_equal(text[0], "0")
    testing.assert_equal(text[999], "9")


def test_big_write():
    # Create a new Buffer Writer and use it to create the buffered Writer
    writer = bufio.Writer(bytes.Buffer())

    # Build a string larger than the size of the Bufio struct's internal buffer.
    builder = StringBuilder(capacity=5000)
    for _ in range(500):
        builder.write("0123456789")

    # When writing, it should bypass the Bufio struct's buffer and write directly to the underlying bytes buffer writer. So, no need to flush.
    text = str(builder)
    writer.write(text)
    testing.assert_equal(len(writer.writer), 5000)
    testing.assert_equal(text[0], "0")
    testing.assert_equal(text[4999], "9")


def test_write_byte():
    # Create a new Buffer Writer and use it to create the buffered Writer
    writer = bufio.Writer(bytes.Buffer("Hello"))

    # Write a byte with the value of 32 to the writer's internal buffer and flush it to the Buffer Writer.
    bytes_written = writer.write_byte(32)
    writer.flush()
    testing.assert_equal(bytes_written, 1)
    testing.assert_equal(writer.writer.consume(), "Hello ")


def test_read_from():
    # Create a new Buffer Writer and use it to create the buffered Writer
    writer = bufio.Writer(bytes.Buffer("Hello"))

    # Read from a ReaderFrom struct into the Buffered Writer's internal buffer and flush it to the Buffer Writer.
    reader_from = bytes.Buffer(" World!")
    result = writer.read_from(reader_from)
    writer.flush()

    testing.assert_equal(result, 7)
    testing.assert_equal(writer.writer.consume(), "Hello World!")
