from tests.wrapper import MojoTest
from gojo.bytes import buffer
from gojo.builtins._bytes import Bytes
from gojo.bufio import Reader, Scanner, scan_words


fn test_reader() raises:
    var test = MojoTest("Testing reader")

    # Create a reader from a string buffer
    var s: String = "Hello"
    var buf = buffer.new_buffer_string(s)
    var r = Reader(buf)

    # Read the buffer into Bytes and then add more to Bytes
    var dest = Bytes(256)
    _ = r.read(dest)
    dest.extend(" World!")

    test.assert_equal(dest, "Hello World!")


fn test_scan_words() raises:
    var test = MojoTest("Testing scan_words")

    # Create a reader from a string buffer
    var s: String = "Testing this string!"
    var buf = buffer.new_buffer_string(s)
    var r = Reader(buf)

    # Create a scanner from the reader
    var scanner = Scanner(r)
    scanner.split = scan_words

    var expected_results = DynamicVector[String]()
    expected_results.append("Testing")
    expected_results.append("this")
    expected_results.append("string!")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.text(), expected_results[i])
        i += 1

fn main() raises:
    test_reader()
    test_scan_words()
