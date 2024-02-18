from math import min
from ..external.libc import Str, c_ssize_t, c_size_t, c_int, char_pointer
from ..builtins._bytes import Bytes, Byte, to_bytes
from .file import File
import .traits


alias O_RDWR = 0o2


# This is a simple wrapper around POSIX-style fcntl.h functions.
# thanks to https://github.com/gabrieldemarmiesse/mojo-stdlib-extensions/ for the original read implementation!
@value
struct Reader(traits.Reader):
    var file: File
    var buffer: Bytes

    fn __init__(inout self, owned file: File):
        alias buffer_size: Int = 2**13
        self.buffer = Bytes(buffer_size)
        self.file = file

    # This takes ownership of a POSIX file descriptor.
    fn __moveinit__(inout self, owned existing: Self):
        self.file = existing.file
        self.buffer = existing.buffer

    fn read(inout self, inout dest: Bytes) raises -> Int:
        var dest_index = 0
        var start = 0
        var end = 0

        # while dest_index < len(dest):
        while dest_index < dest._vector.capacity:
            let written = min(len(dest) - dest_index, end - start)
            if written == 0:
                # buf empty, fill it
                let n = self.file.read(self.buffer)
                if n == 0:
                    # reading from the unbuffered stream returned nothing
                    # so we have nothing left to read.
                    return dest_index
                start = 0
                end = n
            start += written
            dest_index += written
        return len(dest)

    # fn read(inout self, inout dest: Bytes) raises -> Int:
    #     let buf_size = self.buffer.buf._vector.capacity
    #     let fd = int(self.file.handle.load())
    #     let read_count: c_ssize_t = external_call["read", c_ssize_t, c_int, char_pointer, c_size_t](fd, self.buffer.buf._vector.data, buf_size)
    #     if read_count == -1:
    #         raise Error("Failed to read file descriptor " + fd.__str__())

    #     if read_count == self.buffer.buf._vector.capacity:
    #         raise Error(
    #             "You can only read up to "
    #             + String(buf_size)
    #             + " bytes at a time. Adjust the buffer size or handle larger data"
    #             " in segments."
    #         )

    #     return read_count

    # fn read(inout self) raises -> Int:
    #     let buf_size = self.buffer.buf._vector.capacity
    #     let read_count: c_ssize_t = external_call["read", c_ssize_t, c_int, char_pointer, c_size_t](self.fd, self.buffer.buf._vector.data, buf_size)
    #     if read_count == -1:
    #         raise Error("Failed to read file descriptor " + self.fd.__str__())

    #     if read_count == self.buffer.buf._vector.capacity:
    #         raise Error(
    #             "You can only read up to "
    #             + String(buf_size)
    #             + " bytes at a time. Adjust the buffer size or handle larger data"
    #             " in segments."
    #         )

    #     return read_count

    fn string(inout self) raises -> String:
        let position = self.read(self.buffer)
        return self.buffer[:position]

    fn bytes(inout self) raises -> String:
        let position = self.read(self.buffer)
        return self.buffer[:position]

    # # TODO: It writes a bunch of null chars only
    # fn write_to[W: io.Writer](inout self, inout writer: W) raises -> Int64:
    #     var write_count = writer.write(self.buffer.buf)
    #     # if write_count > len(self.buffer.buf):
    #     #     raise Error("std.Reader.write_to: invalid Write count")

    #     # if write_count != len(self.buffer.buf):
    #     #     raise Error(io.ErrShortWrite)

    #     return write_count