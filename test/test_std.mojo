from gojo.syscall import FD
from gojo.io import STDWriter
import testing


def test_writer():
    # var test = MojoTest("Testing STDWriter.write")
    var writer = STDWriter[FD.STDOUT]()
    _ = writer.write_string("")
