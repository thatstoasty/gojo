from tests.wrapper import MojoTest
from gojo.builtins._bytes import Bytes


fn test_bytes() raises:
    var test = MojoTest("Testing bytes")
    var bytes = Bytes("hello")
    test.assert_equal(str(bytes), "hello")

    bytes.append(102)
    test.assert_equal(str(bytes), "hellof")

    bytes += String(" World").as_bytes()
    test.assert_equal(str(bytes), "hellof World")

    var bytes2 = DynamicVector[Int8]()
    bytes2.append(104)
    bytes.extend(bytes2)
    test.assert_equal(str(bytes), "hellof Worldh")


fn main() raises:
    test_bytes()
