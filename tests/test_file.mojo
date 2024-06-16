from tests.wrapper import MojoTest
from gojo.io import read_all, FileWrapper


fn test_read() raises:
    var test = MojoTest("Testing FileWrapper.read")
    var file = FileWrapper("tests/data/test.txt", "r")
    var dest = List[UInt8](capacity=16)
    _ = file.read(dest)
    dest.append(0)
    test.assert_equal(String(dest), "12345")


fn test_read_all() raises:
    var test = MojoTest("Testing FileWrapper.read_all")
    var file = FileWrapper("tests/data/test_big_file.txt", "r")
    var result = file.read_all()
    var bytes = result[0]
    test.assert_equal(len(bytes), 15358)
    bytes.append(0)

    with open("tests/data/test_big_file.txt", "r") as f:
        var expected = f.read()
        test.assert_equal(String(bytes), expected)


fn test_io_read_all() raises:
    var test = MojoTest("Testing io.read_all with FileWrapper")
    var file = FileWrapper("tests/data/test_big_file.txt", "r")
    var result = read_all(file)
    var bytes = result[0]
    test.assert_equal(len(bytes), 15358)
    bytes.append(0)

    with open("tests/data/test_big_file.txt", "r") as f:
        var expected = f.read()
        test.assert_equal(String(bytes), expected)


fn test_read_byte() raises:
    var test = MojoTest("Testing FileWrapper.read_byte")
    var file = FileWrapper("tests/data/test.txt", "r")
    test.assert_equal(int(file.read_byte()[0]), 49)


fn test_write() raises:
    var test = MojoTest("Testing FileWrapper.write")
    var file = FileWrapper("tests/data/test_write.txt", "w")
    var content = String("12345")
    var bytes_written = file.write(content.as_bytes())
    test.assert_equal(bytes_written[0], 5)

    with open("tests/data/test_write.txt", "r") as f:
        var expected = f.read()
        test.assert_equal(content, expected)


fn main() raises:
    test_read()
    test_read_all()
    test_io_read_all()
    test_read_byte()
    test_write()
