import testing
from gojo.bytes import buffer
from gojo.io import FileWrapper
from gojo.bufio import Reader, Scanner, scan_words, scan_bytes, scan_runes


def test_scan_words():
    # var test = MojoTest("Testing bufio.scan_words")

    # Create a reader from a string buffer
    var buf = buffer.Buffer("Testing🔥 this🔥 string🔥!")

    # Create a scanner from the reader
    var scanner = Scanner[split=scan_words](buf^)
    var expected_results = List[String]("Testing🔥", "this🔥", "string🔥!")
    var i = 0
    while scanner.scan():
        testing.assert_equal(scanner.current_token(), expected_results[i])
        i += 1

    testing.assert_equal(i, len(expected_results))


def test_scan_lines():
    # var test = MojoTest("Testing bufio.scan_lines")

    # Create a reader from a string buffer
    var buf = buffer.Buffer("Testing\nthis\nstring!")

    # Create a scanner from the reader
    var scanner = Scanner(buf^)
    var expected_results = List[String]("Testing", "this", "string!")
    var i = 0
    while scanner.scan():
        testing.assert_equal(scanner.current_token(), expected_results[i])
        i += 1

    testing.assert_equal(i, len(expected_results))


def scan_no_newline_test(test_case: String, result_lines: List[String]):
    # Create a reader from a string buffer
    var buf = buffer.Buffer(test_case)

    # Create a scanner from the reader
    var scanner = Scanner(buf^)
    var i = 0
    while scanner.scan():
        testing.assert_equal(scanner.current_token(), result_lines[i])
        i += 1


def test_scan_lines_no_newline():
    # var test = MojoTest("Testing bufio.scan_lines with no final newline")
    var test_case = "abcdefghijklmn\nopqrstuvwxyz"
    var result_lines = List[String]("abcdefghijklmn", "opqrstuvwxyz")

    scan_no_newline_test(test_case, result_lines)


def test_scan_lines_cr_no_newline():
    # var test = MojoTest("Testing bufio.scan_lines with no final newline but carriage return")
    var test_case = "abcdefghijklmn\nopqrstuvwxyz\r"
    var result_lines = List[String]("abcdefghijklmn", "opqrstuvwxyz")

    scan_no_newline_test(test_case, result_lines)


def test_scan_lines_empty_final_line():
    # var test = MojoTest("Testing bufio.scan_lines with an empty final line")
    var test_case = "abcdefghijklmn\nopqrstuvwxyz\n\n"
    var result_lines = List[String]("abcdefghijklmn", "opqrstuvwxyz", "")

    scan_no_newline_test(test_case, result_lines)


def test_scan_lines_cr_empty_final_line():
    # var test = MojoTest("Testing bufio.scan_lines with an empty final line and carriage return")
    var test_case = "abcdefghijklmn\nopqrstuvwxyz\n\r"
    var result_lines = List[String]("abcdefghijklmn", "opqrstuvwxyz", "")

    scan_no_newline_test(test_case, result_lines)


def test_scan_bytes():
    # var test = MojoTest("Testing bufio.scan_bytes")

    var test_cases = List[String]("", "a", "abc", "abc def\n\t\tgh    ")
    for test_case in test_cases:
        # Create a reader from a string buffer
        var buf = buffer.Buffer(buf=test_case[].as_bytes())

        # Create a scanner from the reader
        var scanner = Scanner[split=scan_bytes](buf^)
        var j = 0
        while scanner.scan():
            testing.assert_equal(scanner.current_token(), test_case[][j])
            j += 1

        testing.assert_equal(j, len(test_case[]))


def test_file_wrapper_scanner():
    # var test = MojoTest("testing io.FileWrapper and bufio.Scanner")
    var file = FileWrapper("test/data/test_multiple_lines.txt", "r")

    # Create a scanner from the reader
    var scanner = Scanner(file^)
    var expected_results = List[String]("11111", "22222", "33333", "44444", "55555")
    var i = 0
    while scanner.scan():
        testing.assert_equal(scanner.current_token(), expected_results[i])
        i += 1
    testing.assert_equal(i, len(expected_results))


def test_scan_runes():
    # var test = MojoTest("Testing bufio.scan_runes")

    # Create a reader from a string buffer
    var buf = buffer.Buffer("🔪🔥🔪🔥")

    # Create a scanner from the reader
    var scanner = Scanner[split=scan_runes](buf^)

    var expected_results = List[String]("🔪", "🔥", "🔪", "🔥")
    var i = 0
    while scanner.scan():
        testing.assert_equal(scanner.current_token(), expected_results[i])
        i += 1
    testing.assert_equal(i, len(expected_results))
