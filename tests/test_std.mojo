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
    # _ = r.read()
    # print(r.bytes())
    var w = Writer(int(FD_STDOUT))
    _ = w.read_from(r)
    # _ = r.write_to(w)
    # _ = w.read_from(r)
    # print(r.string())