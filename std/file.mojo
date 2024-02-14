from .external.libc import Str, c_ssize_t, c_size_t, c_int, char_pointer
from gojo.stdlib_extensions.builtins import bytes
from gojo.io import io


alias O_RDWR = 0o2


# This is a simple wrapper around POSIX-style fcntl.h functions.
# thanks to https://github.com/gabrieldemarmiesse/mojo-stdlib-extensions/ for the original read implementation!
@value
struct FileDescriptor(io.Reader, io.Writer):
    var fd: Int

    # This takes ownership of a POSIX file descriptor.
    fn __moveinit__(inout self, owned existing: Self):
        self.fd = existing.fd

    fn __init__(inout self, fd: Int):
        self.fd = fd

    fn __init__(inout self, path: StringLiteral):
        let mode: Int = 0o644  # file permission
        # TODO: handle errors
        self = FileDescriptor(
            external_call["open", Int, StringLiteral, Int, Int](path, O_RDWR, mode)
        )

    fn __del__(owned self):
        _ = external_call["close", Int, Int](self.fd)

    fn dup(self) -> Self:
        let new_fd = external_call["dup", Int, Int](self.fd)
        return Self(new_fd)
    
    fn read(inout self, inout dest: bytes) raises -> Int:
        alias buffer_size: Int = 2**13
        var buf = bytes(buffer_size)
        # let buffer_size = dest._vector.capacity

        let read_count: c_ssize_t = external_call["read", c_ssize_t, c_int, char_pointer, c_size_t](self.fd, buf._vector.data, buffer_size)
        if read_count == -1:
            raise Error("Failed to read file descriptor " + self.fd.__str__())

        if read_count == buffer_size:
            raise Error(
                "You can only read up to "
                + String(buffer_size)
                + " bytes at a time. Adjust the buffer size or handle larger data"
                " in segments."
            )

        return read_count

    fn read(self) raises -> String:
        alias buffer_size: Int = 2**13
        let buffer: Str
        with Str(size=buffer_size) as buffer:
            let read_count: c_ssize_t = external_call[
                "read", c_ssize_t, c_int, char_pointer, c_size_t
            ](self.fd, buffer.vector.data, buffer_size)

            if read_count == -1:
                raise Error("Failed to read file descriptor " + self.fd.__str__())

            if read_count == buffer_size:
                raise Error(
                    "You can only read up to "
                    + String(buffer_size)
                    + " bytes at a time. Adjust the buffer size or handle larger data"
                    " in segments."
                )

            return buffer.to_string(read_count)

    fn write(inout self, src: bytes) raises -> Int:
        let buffer: Str
        with Str(src) as buffer:
            let write_count: c_ssize_t = external_call[
                "write", c_ssize_t, c_int, char_pointer, c_size_t
            ](self.fd, buffer.vector.data, src.__len__())

            if write_count == -1:
                raise Error("Failed to write to file descriptor " + self.fd.__str__())

            return write_count