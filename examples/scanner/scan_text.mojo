from gojo.bytes import buffer
from gojo.bufio import Reader, Scanner, scan_words


fn print_words(owned text: String):
    # Create a reader from a string buffer
    var buf = buffer.new_buffer(text^)
    var r = Reader(buf^)

    # Create a scanner from the reader
    var scanner = Scanner[split=scan_words](r^)

    while scanner.scan():
        print(scanner.current_token())


fn print_lines(owned text: String):
    # Create a reader from a string buffer
    var buf = buffer.new_buffer(text^)
    var r = Reader(buf^)

    # Create a scanner from the reader
    var scanner = Scanner(r^)

    while scanner.scan():
        print(scanner.current_token())


fn main():
    var text = String("Testing this string!")
    var text2 = String("Testing\nthis\nstring!")
    print_words(text^)
    print_lines(text2^)
