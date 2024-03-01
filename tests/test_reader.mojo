from testing import testing
from gojo.bytes import reader, buffer
from gojo.builtins._bytes import Bytes
from gojo.io.io import read_all
import gojo.io.traits as io


fn test_read() raises:
    print("Testing read")
    var r = reader.new_reader(Bytes("0123456789"))
    var b = Bytes()
    _ = r.read(b)
    testing.assert_equal(str(b), "0123456789")


fn test_read_at() raises:
    print("Testing read_at")
    var r = reader.new_reader(Bytes("0123456789"))

    var b = Bytes()
    var pos = r.read_at(b, 0)
    testing.assert_equal(str(b[:pos]), "0123456789")

    b = Bytes()
    pos = r.read_at(b, 1)
    testing.assert_equal(str(b[:pos]), "123456789")

    # TODO: This test case returns the full bytes instead of empty.
    # b = bytes(0)
    # pos = r.read_at(b, 0)
    # testing.assert_equal(b[:pos], Bytes(""))


fn test_seek() raises:
    print("Testing seek")
    var r = reader.new_reader(Bytes("0123456789"))
    var pos = r.seek(5, io.seek_start)

    var b = Bytes()
    _ = r.read(b)
    testing.assert_equal(str(b), "56789")


fn test_read_all() raises:
    print("Testing read_all")
    var r = reader.new_reader(Bytes("0123456789"))
    var result = read_all(r)
    testing.assert_equal(str(result), "0123456789")


fn test_write_to() raises:
    print("Testing write_to")

    # Create a new reader containing the content "0123456789"
    var r = reader.new_reader(Bytes("0123456789"))

    # Create a new writer containing the content "Hello World"
    var test_string: String = "Hello World"
    var w = buffer.new_buffer_string(test_string)

    # Write the content of the reader to the writer
    _ = r.write_to(w)

    # Check if the content of the writer is "Hello World0123456789"
    testing.assert_equal(str(w), String("Hello World0123456789"))


fn reader_tests() raises:
    test_read()
    test_read_at()
    test_seek()
    test_read_all()
    test_write_to()