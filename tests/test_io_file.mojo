from tests.wrapper import MojoTest
from gojo.io.file import FileWrapper
from gojo.builtins import Bytes
from gojo.io import read_all


fn test_read() raises:
    var test = MojoTest("Testing io.FileWrapper.read")
    var file = FileWrapper("tests/data/test.txt", "r")
    var dest = Bytes(128)
    _ = file.read(dest)
    test.assert_equal(String(dest), String(Bytes("12345")))


fn test_read_all() raises:
    var test = MojoTest("Testing io.FileWrapper.read_all")
    var file = FileWrapper("tests/data/test_big_file.txt", "r")
    var result = file.read_all()
    test.assert_equal(len(result.value), 15358)

    with open("tests/data/test_big_file.txt", "r") as f:
        var expected = f.read()
        test.assert_equal(String(result.value), String(Bytes(expected)))


fn test_io_read_all() raises:
    var test = MojoTest("Testing io.read_all with io.FileWrapper")
    var file = FileWrapper("tests/data/test_big_file.txt", "r")
    var result = read_all(file)
    test.assert_equal(len(result.value), 15358)

    with open("tests/data/test_big_file.txt", "r") as f:
        var expected = f.read()
        test.assert_equal(String(result.value), String(Bytes(expected)))


fn test_read_byte() raises:
    var test = MojoTest("Testing io.FileWrapper.read_byte")
    var file = FileWrapper("tests/data/test.txt", "r")
    test.assert_equal(file.read_byte().value, 49)


fn test_write() raises:
    var test = MojoTest("Testing io.FileWrapper.write")
    var file = FileWrapper("tests/data/test_write.txt", "w")
    var src = Bytes("12345")
    var bytes_written = file.write(src)
    test.assert_equal(bytes_written.value, 5)

    var dest = Bytes(128)
    file = FileWrapper("tests/data/test_write.txt", "r")
    var bytes_read = file.read(dest)
    test.assert_equal(bytes_read.value, 5)
    test.assert_equal(String(dest), String(Bytes("12345")))


fn main() raises:
    test_read()
    test_read_all()
    test_io_read_all()
    test_read_byte()
    test_write()
