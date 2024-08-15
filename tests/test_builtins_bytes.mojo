from tests.wrapper import MojoTest
from gojo.builtins.bytes import index_byte


fn test_index_byte():
    var test = MojoTest("Testing builtins.bytes.index_byte")
    var bytes = String("hello\n").as_bytes()
    test.assert_equal(index_byte(bytes, ord("\n")), 5)


fn main():
    test_index_byte()
