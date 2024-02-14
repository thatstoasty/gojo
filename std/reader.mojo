from .external.libc import Str, c_ssize_t, c_size_t, c_int, char_pointer
from gojo.io import io
from gojo.bytes import buffer
from gojo.bytes.util import to_bytes
from gojo.stdlib_extensions.builtins import bytes

alias O_RDWR = 0o2


# This is a simple wrapper around POSIX-style fcntl.h functions.
# thanks to https://github.com/gabrieldemarmiesse/mojo-stdlib-extensions/ for the original read implementation!
@value
struct Reader(io.ReaderWriteTo):
    var fd: Int
    var buffer: buffer.Buffer

    fn __init__(inout self, fd: Int):
        alias buffer_size: Int = 2**13
        self.fd = fd
        var buf = bytes(buffer_size)
        self.buffer = buffer.Buffer(buf)

    fn __init__(inout self, path: StringLiteral):
        alias buffer_size: Int = 2**13
        var buf = bytes(buffer_size)
        self.buffer = buffer.Buffer(buf)
        let mode: Int = 0o644  # file permission
        # TODO: handle errors
        self.fd = external_call["open", Int, StringLiteral, Int, Int](path, O_RDWR, mode)

    # This takes ownership of a POSIX file descriptor.
    fn __moveinit__(inout self, owned existing: Self):
        self.fd = existing.fd
        self.buffer = existing.buffer

    fn __del__(owned self):
        _ = external_call["close", Int, Int](self.fd)

    fn dup(self) -> Self:
        let new_fd = external_call["dup", Int, Int](self.fd)
        return Self(new_fd)

    fn read(inout self, inout dest: bytes) raises -> Int:
        let buf_size = self.buffer.buf._vector.capacity
        let read_count: c_ssize_t = external_call["read", c_ssize_t, c_int, char_pointer, c_size_t](self.fd, self.buffer.buf._vector.data, buf_size)
        if read_count == -1:
            raise Error("Failed to read file descriptor " + self.fd.__str__())

        if read_count == self.buffer.buf._vector.capacity:
            raise Error(
                "You can only read up to "
                + String(buf_size)
                + " bytes at a time. Adjust the buffer size or handle larger data"
                " in segments."
            )

        return read_count
    
    fn read(inout self) raises -> Int:
        let buf_size = self.buffer.buf._vector.capacity
        let read_count: c_ssize_t = external_call["read", c_ssize_t, c_int, char_pointer, c_size_t](self.fd, self.buffer.buf._vector.data, buf_size)
        if read_count == -1:
            raise Error("Failed to read file descriptor " + self.fd.__str__())

        if read_count == self.buffer.buf._vector.capacity:
            raise Error(
                "You can only read up to "
                + String(buf_size)
                + " bytes at a time. Adjust the buffer size or handle larger data"
                " in segments."
            )

        return read_count
    
    fn string(inout self) raises -> String:
        let position = self.read(self.buffer.buf)
        return self.buffer.string()[:position]
    
    fn bytes(inout self) raises -> String:
        let position = self.read(self.buffer.buf)
        print(position)
        return self.buffer.bytes()[:position]

    fn write_to[W: io.Writer](inout self, inout writer: W) raises -> Int64:
        var write_count = writer.write(self.buffer.buf)
        # if write_count > len(self.buffer.buf):
        #     raise Error("std.Reader.write_to: invalid Write count")
        
        # if write_count != len(self.buffer.buf):
        #     raise Error(io.ErrShortWrite)
        
        return write_count
