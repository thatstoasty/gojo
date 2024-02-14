from .external.libc import Str, c_ssize_t, c_size_t, c_int, char_pointer
from gojo.io import io
from gojo.bytes import buffer
from gojo.bytes.util import to_bytes
from gojo.stdlib_extensions.builtins import bytes
from ._file import File

alias O_RDWR = 0o2


# This is a simple wrapper around POSIX-style fcntl.h functions.
# thanks to https://github.com/gabrieldemarmiesse/mojo-stdlib-extensions/ for the original read implementation!
@value
struct Writer(io.WriterReadFrom, io.StringWriter):
    var file: File
    var buffer: bytes
    var end: Int

    fn __init__(inout self, owned file: File):
        alias buffer_size: Int = 2**13
        self.file = file
        self.buffer = bytes(buffer_size)
        self.end = 0
    
    # This takes ownership of a POSIX file descriptor.
    fn __moveinit__(inout self, owned existing: Self):
        self.file = existing.file
        self.buffer = existing.buffer
        self.end = existing.end
    
    fn flush(inout self) raises:
        print("flushing")
        self.file.write_all(self.buffer[:self.end])
        self.end = 0
    
    fn write(inout self, src: bytes) raises -> Int:
        # if self.end + len(src) > src._vector.capacity:
        #     self.flush()
        #     if len(src) > src._vector.capacity:
        #         return self.file.write(src)


        let bytes_written = self.file.write(src)
        let new_end = self.end + bytes_written
        self.end = new_end
        print(self.end)
        return bytes_written
    
    fn write_string(inout self, src: String) raises -> Int:
        print("writing", src)
        print(self.end)
        return self.write(to_bytes(src))
    
    fn read_from[R: io.Reader](inout self, inout reader: R) raises -> Int64:
        _ = reader.read(self.buffer)
        return self.write(self.buffer)

