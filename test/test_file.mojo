from gojo.io import read_all, FileWrapper
from gojo.builtins.bytes import to_string
import testing


def test_read():
    # var test = MojoTest("Testing FileWrapper.read")
    var file = FileWrapper("test/data/test.txt", "r")
    var dest = List[UInt8, True](capacity=16)
    _ = file.read(dest)
    testing.assert_equal(to_string(dest), "12345")


def test_read_all():
    # var test = MojoTest("Testing FileWrapper.read_all")
    var file = FileWrapper("test/data/test_big_file.txt", "r")
    var result = file.read_all()
    var bytes = result[0]
    testing.assert_equal(len(bytes), 15358)
    bytes.append(0)

    with open("test/data/test_big_file.txt", "r") as f:
        var expected = f.read()
        testing.assert_equal(String(bytes), expected)


def test_io_read_all():
    # var test = MojoTest("Testing io.read_all with FileWrapper")
    var file = FileWrapper("test/data/test_big_file.txt", "r")
    var result = read_all(file)
    var bytes = result[0]
    testing.assert_equal(len(bytes), 15358)
    bytes.append(0)

    with open("test/data/test_big_file.txt", "r") as f:
        var expected = f.read()
        testing.assert_equal(String(bytes), expected)


def test_read_byte():
    # var test = MojoTest("Testing FileWrapper.read_byte")
    var file = FileWrapper("test/data/test.txt", "r")
    testing.assert_equal(int(file.read_byte()[0]), 49)


def test_write():
    # var test = MojoTest("Testing FileWrapper.write")
    var file = FileWrapper("test/data/test_write.txt", "w")
    var content = "12345"
    var bytes_written = file.write(content.as_bytes_slice())
    testing.assert_equal(bytes_written[0], 5)

    with open("test/data/test_write.txt", "r") as f:
        var expected = f.read()
        testing.assert_equal(content, expected)
