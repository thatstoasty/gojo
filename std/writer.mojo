from .external.libc import Str, c_ssize_t, c_size_t, c_int, char_pointer
from gojo.io import io
from gojo.bytes import buffer
from gojo.bytes.util import to_bytes
from gojo.stdlib_extensions.builtins import bytes

alias O_RDWR = 0o2


# This is a simple wrapper around POSIX-style fcntl.h functions.
# thanks to https://github.com/gabrieldemarmiesse/mojo-stdlib-extensions/ for the original read implementation!
@value
struct Writer(io.Writer):
    var fd: Int
    var buffer: buffer.Buffer

    fn __init__(inout self, fd: Int):
        alias buffer_size: Int = 2**13
        self.fd = fd
        var buf = bytes(buffer_size)
        self.buffer = buffer.Buffer(buf)
    
    # This takes ownership of a POSIX file descriptor.
    fn __moveinit__(inout self, owned existing: Self):
        self.fd = existing.fd
        self.buffer = existing.buffer

    fn __del__(owned self):
        _ = external_call["close", Int, Int](self.fd)

    fn dup(self) -> Self:
        let new_fd = external_call["dup", Int, Int](self.fd)
        return Self(new_fd)

    fn write(inout self, b: bytes) raises -> Int:
        let write_count: c_ssize_t = external_call["write", c_ssize_t, c_int, char_pointer, c_size_t](self.fd, b._vector.data, b.__len__())

        if write_count == -1:
            raise Error("Failed to write to file descriptor " + self.fd.__str__())

        return write_count
    
    fn write_string(inout self, b: String) raises -> Int:
        return self.write(to_bytes(b))
