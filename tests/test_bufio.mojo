from tests.wrapper import MojoTest
from gojo.bytes import buffer
from gojo.builtins._bytes import Bytes
from gojo.bufio import Reader, Scanner, scan_words, scan_bytes
from gojo.io import FileWrapper


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
    var scanner = Scanner(r ^)
    scanner.split = scan_words

    var expected_results = DynamicVector[String]()
    expected_results.append("Testing")
    expected_results.append("this")
    expected_results.append("string!")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.current_token(), expected_results[i])
        i += 1


fn test_scan_lines() raises:
    var test = MojoTest("Testing scan_lines")

    # Create a reader from a string buffer
    var s: String = "Testing\nthis\nstring!"
    var buf = buffer.new_buffer_string(s)
    var r = Reader(buf)

    # Create a scanner from the reader
    var scanner = Scanner(r ^)

    var expected_results = DynamicVector[String]()
    expected_results.append("Testing")
    expected_results.append("this")
    expected_results.append("string!")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.current_token(), expected_results[i])
        i += 1


fn test_scan_bytes() raises:
    var test = MojoTest("Testing scan_bytes")

    # Create a reader from a string buffer
    var s: String = "abc"
    var buf = buffer.new_buffer_string(s)
    var r = Reader(buf)

    # Create a scanner from the reader
    var scanner = Scanner(r ^)
    scanner.split = scan_bytes

    var expected_results = DynamicVector[String]()
    expected_results.append("a")
    expected_results.append("b")
    expected_results.append("c")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.current_token_as_bytes(), Bytes(expected_results[i]))
        i += 1


fn test_file_wrapper_scanner() raises:
    var test = MojoTest("testing io.FileWrapper and bufio.Scanner")
    var file = FileWrapper("test_multiple_lines.txt", "r")

    # Create a scanner from the reader
    var scanner = Scanner(file ^)
    var expected_results = DynamicVector[String]()
    expected_results.append("11111")
    expected_results.append("22222")
    expected_results.append("33333")
    expected_results.append("44444")
    expected_results.append("55555")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.current_token(), expected_results[i])
        i += 1


fn main() raises:
    test_reader()
    test_scan_words()
    test_scan_lines()
    test_scan_bytes()
    test_file_wrapper_scanner()