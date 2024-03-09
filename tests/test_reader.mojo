from tests.wrapper import MojoTest
from gojo.bytes import reader, buffer
from gojo.builtins._bytes import Bytes
from gojo.io.io import read_all
import gojo.io.traits as io


fn test_read() raises:
    var test = MojoTest("Testing read")
    var r = reader.new_reader(Bytes("0123456789"))
    var b = Bytes(128)
    _ = r.read(b)
    test.assert_equal(str(b), "0123456789")


fn test_read_at() raises:
    var test = MojoTest("Testing read_at")
    var r = reader.new_reader(Bytes("0123456789"))

    var b = Bytes(128)
    var pos = r.read_at(b, 0)
    test.assert_equal(str(b), "0123456789")

    b = Bytes(128)
    pos = r.read_at(b, 1)
    test.assert_equal(str(b), "123456789")


fn test_seek() raises:
    var test = MojoTest("Testing seek")
    var r = reader.new_reader(Bytes("0123456789"))
    var pos = r.seek(5, io.SEEK_START)

    var b = Bytes(128)
    _ = r.read(b)
    test.assert_equal(str(b), "56789")


fn test_read_all() raises:
    var test = MojoTest("Testing read_all")
    var r = reader.new_reader(Bytes("0123456789"))
    var result = read_all(r)
    test.assert_equal(str(result), "0123456789")


fn test_write_to() raises:
    var test = MojoTest("Testing write_to")

    # Create a new reader containing the content "0123456789"
    var r = reader.new_reader(Bytes("0123456789"))

    # Create a new writer containing the content "Hello World"
    var test_string: String = "Hello World"
    var w = buffer.new_buffer(test_string)

    # Write the content of the reader to the writer
    _ = r.write_to(w)

    # Check if the content of the writer is "Hello World0123456789"
    test.assert_equal(str(w), String("Hello World0123456789"))


fn main() raises:
    test_read()
    test_read_at()
    test_seek()
    test_read_all()
    test_write_to()
