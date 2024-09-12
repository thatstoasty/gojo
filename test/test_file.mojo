from gojo.io import read_all, FileWrapper
from gojo.builtins.bytes import to_string
import pathlib
import testing


def test_read():
    var test_file = str(pathlib._dir_of_current_file()) + "/data/test.txt"
    var file = FileWrapper(test_file, "r")
    var dest = List[UInt8, True](capacity=16)
    _ = file.read(dest)
    testing.assert_equal(to_string(dest), "12345\n")


def test_read_all():
    var test_file = str(pathlib._dir_of_current_file()) + "/data/test_big_file.txt"
    var file = FileWrapper(test_file, "r")
    var result = file.read_all()
    var bytes = result[0]
    testing.assert_equal(len(bytes), 15359)
    bytes.append(0)

    with open(test_file, "r") as f:
        var expected = f.read()
        testing.assert_equal(String(bytes), expected)


def test_io_read_all():
    var test_file = str(pathlib._dir_of_current_file()) + "/data/test_big_file.txt"
    var file = FileWrapper(test_file, "r")
    var result = read_all(file)
    var bytes = result[0]
    testing.assert_equal(len(bytes), 15359)
    bytes.append(0)

    with open(test_file, "r") as f:
        var expected = f.read()
        testing.assert_equal(String(bytes), expected)


def test_read_byte():
    var test_file = str(pathlib._dir_of_current_file()) + "/data/test.txt"
    var file = FileWrapper(test_file, "r")
    testing.assert_equal(int(file.read_byte()[0]), 49)


def test_write():
    var test_file = str(pathlib._dir_of_current_file()) + "/data/test_write.txt"
    var file = FileWrapper(test_file, "w")
    var content = "12345"
    var bytes_written = file.write(content.as_bytes_slice())
    testing.assert_equal(bytes_written[0], 5)

    with open(test_file, "r") as f:
        var expected = f.read()
        testing.assert_equal(content, expected)
