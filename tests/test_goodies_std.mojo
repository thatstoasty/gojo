from tests.wrapper import MojoTest
from external.libc import FD_STDOUT, FD_STDIN, FD_STDERR
from goodies import STDWriter


fn test_writer() raises:
    var test = MojoTest("Testing goodies.STDWriter")
    var writer = STDWriter(int(FD_STDOUT))
    _ = writer.write_string("")


fn main() raises:
    test_writer()
