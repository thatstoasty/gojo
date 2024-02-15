from .external.libc import Str, c_ssize_t, c_size_t, c_int, char_pointer
from gojo.io import io
from gojo.bytes import buffer
from gojo.bytes.util import to_bytes
from gojo.stdlib_extensions.builtins import bytes

alias O_RDWR = 0o2


# This is a simple wrapper around POSIX-style fcntl.h functions.
# thanks to https://github.com/gabrieldemarmiesse/mojo-stdlib-extensions/ for the original read implementation!
@value
struct STDWriter(io.Writer):
    var fd: Int
    var buffer: bytes

    fn __init__(inout self, fd: Int):
        alias buffer_size: Int = 4096
        self.fd = fd
        self.buffer = bytes()
    
    # This takes ownership of a POSIX file descriptor.
    fn __moveinit__(inout self, owned existing: Self):
        self.fd = existing.fd
        self.buffer = existing.buffer

    fn __del__(owned self):
        _ = external_call["close", Int, Int](self.fd)

    fn dup(self) -> Self:
        let new_fd = external_call["dup", Int, Int](self.fd)
        return Self(new_fd)

    fn write(inout self, src: bytes) raises -> Int:
        let write_count: c_ssize_t = external_call["write", c_ssize_t, c_int, char_pointer, c_size_t](self.fd, src._vector.data, src.__len__())

        if write_count == -1:
            raise Error("Failed to write to file descriptor " + self.fd.__str__())

        return write_count
    
    fn write_string(inout self, src: String) raises -> Int:
        return self.write(to_bytes(src))
    
    # fn read_from[R: io.Reader](inout self, inout reader: R) raises -> Int64:
    #     _ = reader.read(self.buffer)
    #     # print("read from reader: ", self.buffer)
    #     return self.write(self.buffer)
