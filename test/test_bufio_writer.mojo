import gojo.bytes
import gojo.bufio
import gojo.io
from gojo.builtins.bytes import to_string
from gojo.strings import StringBuilder
import testing


def test_write():
    # Create a new Buffer Writer and use it to create the buffered Writer
    var writer = bufio.Writer(bytes.Buffer())

    # Write the content from src to the buffered writer's internal buffer and flush it to the Buffer Writer.
    var src = String("0123456789").as_bytes_slice()
    var result = writer.write(src)
    _ = writer.flush()

    testing.assert_equal(result[0], 10)
    testing.assert_equal(str(writer.writer), "0123456789")


def test_several_writes():
    # Create a new Buffer Writer and use it to create the buffered Writer
    var writer = bufio.Writer(bytes.Buffer(capacity=1100))

    # Write the content from src to the buffered writer's internal buffer and flush it to the Buffer Writer.
    var src = String("0123456789")
    for _ in range(100):
        _ = writer.write_string(src)
    _ = writer.flush()

    testing.assert_equal(len(writer.writer), 1000)
    var text = str(writer.writer)
    testing.assert_equal(text[0], "0")
    testing.assert_equal(text[999], "9")


def test_several_writes_small_buffer():
    # Create a new Buffer Writer and use it to create the buffered Writer
    var writer = bufio.Writer(bytes.Buffer(capacity=1000), capacity=16)

    # Write the content from src to the buffered writer's internal buffer and flush it to the Buffer Writer.
    var src = String("0123456789")
    for _ in range(100):
        _ = writer.write_string(src)
    _ = writer.flush()

    var text = str(writer.writer)
    testing.assert_equal(len(text), 1000)
    testing.assert_equal(text[0], "0")
    testing.assert_equal(text[999], "9")


def test_big_write():
    # Create a new Buffer Writer and use it to create the buffered Writer
    var writer = bufio.Writer(bytes.Buffer())

    # Build a string larger than the size of the Bufio struct's internal buffer.
    var builder = StringBuilder(capacity=5000)
    for _ in range(500):
        _ = builder.write_string("0123456789")

    # When writing, it should bypass the Bufio struct's buffer and write directly to the underlying bytes buffer writer. So, no need to flush.
    var text = str(builder)
    _ = writer.write(text.as_bytes_slice())
    testing.assert_equal(len(writer.writer), 5000)
    testing.assert_equal(text[0], "0")
    testing.assert_equal(text[4999], "9")


def test_write_byte():
    # Create a new Buffer Writer and use it to create the buffered Writer
    var writer = bufio.Writer(bytes.Buffer("Hello"))

    # Write a byte with the value of 32 to the writer's internal buffer and flush it to the Buffer Writer.
    var result = writer.write_byte(32)
    _ = writer.flush()

    testing.assert_equal(result[0], 1)
    testing.assert_equal(str(writer.writer), "Hello ")


def test_write_string():
    # Create a new Buffer Writer and use it to create the buffered Writer
    var writer = bufio.Writer(bytes.Buffer("Hello"))

    # Write a string to the writer's internal buffer and flush it to the Buffer Writer.
    var result = writer.write_string(" World!")
    _ = writer.flush()

    testing.assert_equal(result[0], 7)
    testing.assert_equal(str(writer.writer), "Hello World!")


def test_read_from():
    # Create a new Buffer Writer and use it to create the buffered Writer
    var writer = bufio.Writer(bytes.Buffer("Hello"))

    # Read from a ReaderFrom struct into the Buffered Writer's internal buffer and flush it to the Buffer Writer.
    var reader_from = bytes.Buffer(" World!")
    var result = writer.read_from(reader_from)
    _ = writer.flush()

    testing.assert_equal(int(result[0]), 7)
    testing.assert_equal(str(writer.writer), "Hello World!")
