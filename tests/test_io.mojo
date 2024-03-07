from testing import testing
from gojo.io.file import File, FileWrapper
from gojo.io.reader import Reader
from gojo.io.std_writer import STDWriter
from gojo.external.libc import FD_STDOUT, FD_STDIN, FD_STDERR
from gojo.builtins._bytes import Bytes


fn test_file() raises:
    print("testing FileWrapper")
    var file = FileWrapper("test.txt", "r")
    var dest = Bytes(1200)
    _ = file.read(dest)
    testing.assert_equal(String(dest), String(Bytes("12345")))


# TODO: Doesn't work
fn test_reader() raises:
    print("testing Reader")
    # var file = File("test.txt", "r")
    # var reader = Reader(file ^)
    # var dest = Bytes()
    # _ = reader.read(dest)
    # testing.assert_equal(String(dest), String(Bytes("12345")))


fn test_writer() raises:
    print("testing STDWriter")
    var writer = STDWriter(int(FD_STDOUT))
    _ = writer.write_string("")


fn main() raises:
    test_file()
    test_reader()
    test_writer()
