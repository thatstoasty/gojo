from gojo.bytes import reader, buffer
from gojo.bytes.util import to_bytes
from gojo.stdlib_extensions.builtins import bytes
from gojo.io import io
from gojo.io.io import read_all
from testing import testing


fn test_read() raises:
    print("Testing read")
    var r = reader.new_reader(to_bytes("0123456789"))
    var b = bytes()
    _ = r.read(b)
    testing.assert_equal(b, to_bytes("0123456789"))


fn test_read_at() raises:
    print("Testing read_at")
    var r = reader.new_reader(to_bytes("0123456789"))

    var b = bytes()
    var pos = r.read_at(b, 0)
    testing.assert_equal(b[:pos], to_bytes("0123456789"))
    
    b = bytes()
    pos = r.read_at(b, 1)
    testing.assert_equal(b[:pos], to_bytes("123456789"))

    # TODO: This test case returns the full bytes instead of empty.
    # b = bytes(0)
    # pos = r.read_at(b, 0)
    # testing.assert_equal(b[:pos], to_bytes(""))


fn test_seek() raises:
    print("Testing seek")
    var r = reader.new_reader(to_bytes("0123456789"))
    let pos = r.seek(5, io.seek_start)
    
    var b = bytes()
    _ = r.read(b)
    testing.assert_equal(b, to_bytes("56789"))


fn test_read_all() raises:
    print("Testing read_all")
    var r = reader.new_reader(to_bytes("0123456789"))
    let result = read_all(r)
    testing.assert_equal(result, to_bytes("0123456789"))


fn test_write_to() raises:
    print("Testing write_to")

    # Create a new reader containing the content "0123456789"
    var r = reader.new_reader(to_bytes("0123456789"))

    # Create a new writer containing the content "Hello World"
    var test_string: String = "Hello World"
    var w = buffer.new_buffer_string(test_string)

    # Write the content of the reader to the writer
    _ = r.write_to(w)

    # Check if the content of the writer is "Hello World0123456789"
    testing.assert_equal(w.string(), String("Hello World0123456789"))


fn main() raises:
    test_read()
    test_read_at()
    test_seek()
    test_read_all()
    test_write_to()
