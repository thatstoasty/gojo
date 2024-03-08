from tests.wrapper import MojoTest
from gojo.bytes import buffer
from gojo.builtins._bytes import Bytes
from gojo.bufio import Writer


fn test_writer():
    var test = MojoTest("Testing bufio.Writer")


fn main():
    test_writer()
