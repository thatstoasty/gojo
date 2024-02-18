from testing import testing
from gojo.io.file import File, FileWrapper
from gojo.io.reader import Reader
from gojo.io.std_writer import STDWriter
from gojo.external.libc import FD_STDOUT, FD_STDIN, FD_STDERR
from gojo.builtins._bytes import Bytes, to_bytes


fn test_file() raises:
    print("testing FileWrapper")
    var file = FileWrapper("test.txt", "r")
    var dest = Bytes(1200)
    _ = file.read(dest)
    testing.assert_equal(String(dest), String(to_bytes("12345")))


fn test_reader() raises:
    print("testing Reader")
    # FIXME: Reader.read is not working atm. No data gets loaded to the bytes buffer
    # var file = File("test.txt", "r")
    # var reader = Reader(file ^)
    # var dest = Bytes()
    # _ = reader.read(dest)
    # testing.assert_equal(dest.__str__(), to_bytes("12345"))


fn test_writer() raises:
    print("testing STDWriter")
    var writer = STDWriter(int(FD_STDOUT))
    _ = writer.write_string("")


fn io_tests() raises:
    test_file()
    test_reader()
    test_writer()