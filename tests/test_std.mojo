from tests.wrapper import MojoTest
from gojo.syscall import FD
from gojo.io import STDWriter


fn test_writer() raises:
    var test = MojoTest("Testing STDWriter.write")
    var writer = STDWriter[FD.STDOUT]()
    _ = writer.write_string("")


fn main() raises:
    test_writer()
