from tests.wrapper import MojoTest
from gojo.bytes import buffer
from gojo.io import FileWrapper
from gojo.bufio import Reader, Scanner, scan_words, scan_bytes, scan_runes


fn test_scan_words():
    var test = MojoTest("Testing bufio.scan_words")

    # Create a reader from a string buffer
    var s: String = "Testing this string!"
    var buf = buffer.new_buffer(s)
    var r = Reader(buf^)

    # Create a scanner from the reader
    var scanner = Scanner[split=scan_words](r^)

    var expected_results = List[String]("Testing", "this", "string!")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.current_token(), expected_results[i])
        i += 1


fn test_scan_lines():
    var test = MojoTest("Testing bufio.scan_lines")

    # Create a reader from a string buffer
    var s: String = "Testing\nthis\nstring!"
    var buf = buffer.new_buffer(s)
    var r = Reader(buf^)

    # Create a scanner from the reader
    var scanner = Scanner(r^)

    var expected_results = List[String]("Testing", "this", "string!")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.current_token(), expected_results[i])
        i += 1


fn scan_no_newline_test(test_case: String, result_lines: List[String], test: MojoTest):
    # Create a reader from a string buffer
    var buf = buffer.new_buffer(test_case)
    var r = Reader(buf^)

    # Create a scanner from the reader
    var scanner = Scanner(r^)
    var i = 0
    while scanner.scan():
        test.assert_equal(scanner.current_token(), result_lines[i])
        i += 1


fn test_scan_lines_no_newline():
    var test = MojoTest("Testing bufio.scan_lines with no final newline")
    var test_case = "abcdefghijklmn\nopqrstuvwxyz"
    var result_lines = List[String]("abcdefghijklmn", "opqrstuvwxyz")

    scan_no_newline_test(test_case, result_lines, test)


fn test_scan_lines_cr_no_newline():
    var test = MojoTest("Testing bufio.scan_lines with no final newline but carriage return")
    var test_case = "abcdefghijklmn\nopqrstuvwxyz\r"
    var result_lines = List[String]("abcdefghijklmn", "opqrstuvwxyz")

    scan_no_newline_test(test_case, result_lines, test)


fn test_scan_lines_empty_final_line():
    var test = MojoTest("Testing bufio.scan_lines with an empty final line")
    var test_case = "abcdefghijklmn\nopqrstuvwxyz\n\n"
    var result_lines = List[String]("abcdefghijklmn", "opqrstuvwxyz", "")

    scan_no_newline_test(test_case, result_lines, test)


fn test_scan_lines_cr_empty_final_line():
    var test = MojoTest("Testing bufio.scan_lines with an empty final line and carriage return")
    var test_case = "abcdefghijklmn\nopqrstuvwxyz\n\r"
    var result_lines = List[String]("abcdefghijklmn", "opqrstuvwxyz", "")

    scan_no_newline_test(test_case, result_lines, test)


fn test_scan_bytes():
    var test = MojoTest("Testing bufio.scan_bytes")

    var test_cases = List[String]("", "a", "abc", "abc def\n\t\tgh    ")

    for i in range(len(test_cases)):
        var test_case = test_cases[i]
        # Create a reader from a string buffer
        var buf = buffer.new_buffer(test_case)
        var reader = Reader(buf^)

        # Create a scanner from the reader
        var scanner = Scanner[split=scan_bytes](reader^)

        var j = 0
        while scanner.scan():
            test.assert_equal(scanner.current_token(), test_case[j])
            j += 1


fn test_file_wrapper_scanner() raises:
    var test = MojoTest("testing io.FileWrapper and bufio.Scanner")
    var file = FileWrapper("tests/data/test_multiple_lines.txt", "r")

    # Create a scanner from the reader
    var scanner = Scanner(file^)
    var expected_results = List[String]("11111", "22222", "33333", "44444", "55555")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.current_token(), expected_results[i])
        i += 1


fn test_scan_runes():
    var test = MojoTest("Testing bufio.scan_runes")

    # Create a reader from a string buffer
    var s: String = "🔪🔥🔪"
    var buf = buffer.new_buffer(s)
    var r = Reader(buf^)

    # Create a scanner from the reader
    var scanner = Scanner[split=scan_runes](r^)

    var expected_results = List[String]("🔪", "🔥", "🔪")
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
    test_scan_runes()
