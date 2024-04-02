from tests.wrapper import MojoTest
from gojo.bytes import buffer
from gojo.builtins.bytes import Byte
from gojo.bufio import Reader, Scanner, scan_words, scan_bytes
from goodies import FileWrapper


fn test_scan_words() raises:
    var test = MojoTest("Testing scan_words")

    # Create a reader from a string buffer
    var s: String = "Testing this string!"
    var buf = buffer.new_buffer(s)
    var r = Reader(buf)

    # Create a scanner from the reader
    var scanner = Scanner(r ^)
    scanner.split = scan_words

    var expected_results = List[String]()
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
    var buf = buffer.new_buffer(s)
    var r = Reader(buf)

    # Create a scanner from the reader
    var scanner = Scanner(r ^)

    var expected_results = List[String]()
    expected_results.append("Testing")
    expected_results.append("this")
    expected_results.append("string!")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.current_token(), expected_results[i])
        i += 1


fn scan_no_newline_test(
    test_case: String, result_lines: List[String], test: MojoTest
) raises:
    # Create a reader from a string buffer
    var buf = buffer.new_buffer(test_case)
    var r = Reader(buf)

    # Create a scanner from the reader
    var scanner = Scanner(r ^)
    var i = 0
    while scanner.scan():
        test.assert_equal(scanner.current_token(), result_lines[i])
        i += 1


fn test_scan_lines_no_newline() raises:
    var test = MojoTest("Testing bufio.scan_lines with no final newline")
    var test_case = "abcdefghijklmn\nopqrstuvwxyz"
    var result_lines = List[String]()
    result_lines.append("abcdefghijklmn")
    result_lines.append("opqrstuvwxyz")

    scan_no_newline_test(test_case, result_lines, test)


fn test_scan_lines_cr_no_newline() raises:
    var test = MojoTest(
        "Testing bufio.scan_lines with no final newline but carriage return"
    )
    var test_case = "abcdefghijklmn\nopqrstuvwxyz\r"
    var result_lines = List[String]()
    result_lines.append("abcdefghijklmn")
    result_lines.append("opqrstuvwxyz")

    scan_no_newline_test(test_case, result_lines, test)


fn test_scan_lines_empty_final_line() raises:
    var test = MojoTest("Testing bufio.scan_lines with an empty final line")
    var test_case = "abcdefghijklmn\nopqrstuvwxyz\n\n"
    var result_lines = List[String]()
    result_lines.append("abcdefghijklmn")
    result_lines.append("opqrstuvwxyz")
    result_lines.append("")

    scan_no_newline_test(test_case, result_lines, test)


fn test_scan_lines_cr_empty_final_line() raises:
    var test = MojoTest(
        "Testing bufio.scan_lines with an empty final line and carriage return"
    )
    var test_case = "abcdefghijklmn\nopqrstuvwxyz\n\r"
    var result_lines = List[String]()
    result_lines.append("abcdefghijklmn")
    result_lines.append("opqrstuvwxyz")
    result_lines.append("")

    scan_no_newline_test(test_case, result_lines, test)


fn test_scan_bytes() raises:
    var test = MojoTest("Testing scan_bytes")

    var test_cases = List[String]()
    test_cases.append("")
    test_cases.append("a")
    test_cases.append("abc")
    test_cases.append("abc def\n\t\tgh    ")

    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        # Create a reader from a string buffer
        var buf = buffer.new_buffer(test_case)
        var reader = Reader(buf)

        # Create a scanner from the reader
        var scanner = Scanner(reader ^)
        scanner.split = scan_bytes

        var j = 0

        while scanner.scan():
            test.assert_equal(scanner.current_token_as_bytes(), test_case[j].as_bytes())
            j += 1


fn test_file_wrapper_scanner() raises:
    var test = MojoTest("testing io.FileWrapper and bufio.Scanner")
    var file = FileWrapper("tests/data/test_multiple_lines.txt", "r")

    # Create a scanner from the reader
    var scanner = Scanner(file ^)
    var expected_results = List[String]()
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
    test_scan_words()
    test_scan_lines()
    test_scan_lines_no_newline()
    test_scan_lines_cr_no_newline()
    test_scan_lines_empty_final_line()
    test_scan_lines_cr_empty_final_line()
    test_scan_bytes()
    test_file_wrapper_scanner()
