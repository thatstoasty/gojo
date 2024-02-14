from std.file import FileDescriptor
from std._file import File
from std.reader import Reader
from std.writer import Writer
from std.external.libc import FD_STDOUT, FD_STDIN, FD_STDERR
from gojo.stdlib_extensions.builtins import bytes


# fn test_file() raises:
#     var file = File("2.txt", "r")
#     var dest = bytes(4096)
#     print(file.read(dest))
#     print(dest)


fn test_reader() raises:
    var file = File("2.txt", "r")
    var r = Reader(file ^)
    var dest = bytes()
    _ = r.read(dest)
    print(r.bytes())


fn main() raises:
    # test_file()
    test_reader()
    # var f = Writer(int(FD_STDOUT))
    # _ = f.write_string("Hello, world!\n")
    # var e = Writer(int(FD_STDERR))
    # _ = e.write_string("Goodbye, World!\n")

    # var r = Reader(int(FD_STDIN))
    # var file = FileDescriptor("2.txt")
    # # var file = File("test.txt", "r")
    # var r = Reader(file)
    # var b = bytes(4096)
    # _ = r.read(b)
    # print(b)
    # _ = file.read(b)
    # print(b)
    # var r = Reader(file)
    # print(r.bytes())
    # _ = r.read()
    # print(r.bytes())
    # var w = Writer(int(FD_STDOUT))
    # _ = w.read_from(r)
    # _ = r.write_to(w)
    # _ = w.read_from(r)
    # print(r.string())