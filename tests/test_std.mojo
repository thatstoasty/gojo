from std.reader import Reader
from std.writer import Writer
from std.external.libc import FD_STDOUT, FD_STDIN, FD_STDERR

fn main() raises:
    # var f = Writer(int(FD_STDOUT))
    # _ = f.write_string("Hello, world!\n")
    # var e = Writer(int(FD_STDERR))
    # _ = e.write_string("Goodbye, World!\n")

    # var r = Reader(int(FD_STDIN))
    var r = Reader("test.txt")
    print(r.string())