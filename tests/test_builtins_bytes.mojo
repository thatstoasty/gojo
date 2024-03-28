from tests.wrapper import MojoTest
from testing import testing
from gojo.builtins._bytes import Bytes


fn test_bytes_extend_append_and_iadd():
    var test = MojoTest("Testing builtins.Bytes extend, append, and iadd")
    var bytes = Bytes("hello")
    test.assert_equal(str(bytes), "hello")

    bytes.append(102)
    test.assert_equal(str(bytes), "hellof")

    bytes += String(" World").as_bytes()
    test.assert_equal(str(bytes), "hellof World")

    var bytes2 = List[Int8]()
    bytes2.append(104)
    bytes.extend(bytes2)
    test.assert_equal(str(bytes), "hellof Worldh")


fn test_bytes_from_strings():
    var test = MojoTest("Testing builtins.Bytes from strings")
    var bytes = Bytes("hello", "world")
    test.assert_equal(str(bytes), "helloworld")


fn test_bytes_from_dynamic_vector():
    var test = MojoTest("Testing builtins.Bytes from List of Bytes")
    var data = List[Int8]()
    data.append(104)
    data.append(104)
    var bytes = Bytes(data)
    test.assert_equal(String(bytes), "hh")


fn test_slice():
    var test = MojoTest("Testing builtins.Bytes slice")
    var bytes = Bytes("hello")
    test.assert_equal(bytes[0:2], "he")


# fn test_slice_out_of_bounds() raises:
#     var test = MojoTest("Testing builtins.Bytes slice out of bounds")
#     var bytes = Bytes("hello")
#     var successful = True

#     try:
#         with testing.assert_raises(contains="Bytes: Index out of range"):
#             _ = bytes[0:100000000]
#     except e:
#         # If it's some other error other than OOB, reraise it.
#         if "Bytes: Index out of range" not in str(e):
#             raise
#         successful = False

#     test.assert_true(successful)


fn test_index_byte():
    var test = MojoTest("Testing builtins.Bytes slice")
    var bytes = Bytes("hello\n")
    test.assert_equal(bytes.index_byte(ord("\n")), 5)


fn test_size_and_len():
    var test = MojoTest("Testing builtins.Bytes.size and builtins.Bytes.__len__")
    var bytes = Bytes(4096)

    # Size is the number of bytes used, len is the number of bytes allocated.
    test.assert_equal(bytes.size(), 4096)
    test.assert_equal(len(bytes), 0)


fn main():
    test_bytes_extend_append_and_iadd()
    test_bytes_from_strings()
    test_bytes_from_dynamic_vector()
    test_slice()
    # test_slice_out_of_bounds()
    test_index_byte()
    test_size_and_len()
