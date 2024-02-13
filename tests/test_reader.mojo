from gojo.bytes import reader
from gojo.bytes.util import to_bytes
from gojo.stdlib_extensions.builtins import bytes
from gojo.io import io
from testing import testing


fn test_read() raises:
    var r = reader.new_reader(to_bytes("0123456789"))
    var b = bytes()
    _ = r.read(b)
    testing.assert_equal(b, to_bytes("0123456789"))


fn test_read_at() raises:
    var r = reader.new_reader(to_bytes("0123456789"))

    var b = bytes()
    var pos = r.read_at(b, 0)
    testing.assert_equal(b[:pos], to_bytes("0123456789"))
    
    b = bytes()
    pos = r.read_at(b, 1)
    testing.assert_equal(b[:pos], to_bytes("123456789"))


fn test_seek() raises:
    var r = reader.new_reader(to_bytes("0123456789"))
    let pos = r.seek(5, io.seek_start)
    var b = bytes()
    _ = r.read(b)
    testing.assert_equal(b, to_bytes("56789"))


fn main() raises:
    test_read()
    test_read_at()
    test_seek()
