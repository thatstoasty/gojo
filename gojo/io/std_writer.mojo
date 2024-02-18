from ..external.libc import c_ssize_t, c_size_t, c_int, char_pointer
from ..builtins._bytes import Bytes, Byte, to_bytes
from .traits import Writer


@value
struct STDWriter(Writer):
    var fd: Int

    fn __init__(inout self, fd: Int):
        self.fd = fd

    # This takes ownership of a POSIX file descriptor.
    fn __moveinit__(inout self, owned existing: Self):
        self.fd = existing.fd

    fn dup(self) -> Self:
        let new_fd = external_call["dup", Int, Int](self.fd)
        return Self(new_fd)

    fn write(inout self, src: Bytes) raises -> Int:
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