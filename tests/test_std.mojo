from io.file import File, FileWrapper
from io.reader import Reader
from io.writer import STDWriter
from io.external.libc import FD_STDOUT, FD_STDIN, FD_STDERR
from gojo.stdlib_extensions.builtins import bytes
from gojo.bytes.util import to_bytes


fn test_file() raises:
    # var file = File("2.txt", "r")
    # var dest = bytes(4096)
    # print(file.read(dest))
    # print(dest)
    var file = FileWrapper("test.txt", "r")
    var dest = bytes(1200)
    print(file.read(dest))
    print(dest)


fn test_reader() raises:
    var file = File("test.txt", "r")
    var reader = Reader(file ^)
    var dest = bytes()
    _ = reader.read(dest)
    # print(reader.bytes())


fn test_writer() raises:
    # var file = FileWrapper("2.txt", "r")
    var writer = STDWriter(int(FD_STDOUT))
    # var file = File("3.txt", "w")
    # var writer = Writer(file ^)
    # var src = to_bytes(String("12345"))
    # let bytes_written = writer.write(src)
    _ = writer.write_string("Hello")
    # _ = writer.read_from(reader)
    # _ = writer.read_from(reader)
    # print(bytes_written)


fn main() raises:
    test_file()
    # test_writer()
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