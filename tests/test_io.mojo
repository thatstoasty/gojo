from tests.wrapper import MojoTest
from gojo.io.file import FileWrapper
from gojo.io.std_writer import STDWriter
from gojo.external.libc import FD_STDOUT, FD_STDIN, FD_STDERR
from gojo.builtins._bytes import Bytes


fn test_file_wrapper() raises:
    var test = MojoTest("Testing io.FileWrapper")
    var file = FileWrapper("test.txt", "r")
    var dest = Bytes(4096)
    _ = file.read(dest)
    test.assert_equal(String(dest), String(Bytes("12345")))


fn test_writer() raises:
    var test = MojoTest("Testing io.STDWriter")
    var writer = STDWriter(int(FD_STDOUT))
    _ = writer.write_string("")


fn main() raises:
    test_file_wrapper()
    test_writer()
