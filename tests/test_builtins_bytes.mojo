from tests.wrapper import MojoTest
from testing import testing
from gojo.builtins.bytes import Byte, index_byte


fn test_index_byte():
    var test = MojoTest("Testing builtins.List[Byte] slice")
    var bytes = String("hello\n").as_bytes()
    test.assert_equal(index_byte(bytes, ord("\n")), 5)


fn test_size_and_len():
    var test = MojoTest("Testing builtins.List[Byte].size and builtins.List[Byte].__len__")
    var bytes = List[Byte](capacity=16)

    # Size is the number of bytes used, len is the number of bytes allocated.
    test.assert_equal(bytes.capacity, 16)
    test.assert_equal(len(bytes), 0)


fn main():
    # test_slice_out_of_bounds()
    test_index_byte()
    test_size_and_len()
