from tests.wrapper import MojoTest
from gojo.syscall import FD
from goodies import STDWriter


fn test_writer() raises:
    var test = MojoTest("Testing goodies.STDWriter")
    var writer = STDWriter(int(FD.FD_STDOUT))
    _ = writer.write_string("")


fn main() raises:
    test_writer()
