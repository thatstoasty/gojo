from math import min
from memory.memory import memcpy
from ..external.libc import Str, c_ssize_t, c_size_t, c_int, char_pointer
from ..builtins._bytes import Bytes, Byte
from .file import File
import .traits


alias O_RDWR = 0o2
alias BUFFER_SIZE: Int = 4096


# TODO: Doesn't work ATM
@value
struct Reader(traits.Reader):
    var file: File
    var buffer: Bytes

    fn __init__(inout self, owned file: File):
        self.buffer = Bytes(size=BUFFER_SIZE)
        self.file = file

    # This takes ownership of a POSIX file descriptor.
    fn __moveinit__(inout self, owned existing: Self):
        self.file = existing.file ^
        self.buffer = existing.buffer

    fn read(inout self, inout dest: Bytes) raises -> Int:
        var dest_index = 0
        var start = 0
        var end = 0

        print(dest_index, len(dest))
        while dest_index < len(dest) + 1:
            var written = min(len(dest) - dest_index, end - start)
            var dest_ptr: Pointer[UInt8] = dest._vector.data.bitcast[UInt8]().value
            var src_ptr: Pointer[UInt8] = self.buffer._vector.data.bitcast[UInt8]().value
            memcpy(dest_ptr.offset(dest_index), src_ptr.offset(start), written)
            if written == 0:
                # buf empty, fill it
                var n = self.file.read(self.buffer)
                print(self.buffer)
                if n == 0:
                    # reading from the unbuffered stream returned nothing
                    # so we have nothing left to read.
                    return dest_index
                start = 0
                end = n
            start += written
            dest_index += written
        return len(dest)

    fn __str__(inout self) raises -> String:
        var position = self.read(self.buffer)
        return self.buffer[:position]

    fn bytes(inout self) raises -> String:
        var position = self.read(self.buffer)
        return self.buffer[:position]

    # # TODO: It writes a bunch of null chars only
    # fn write_to[W: io.Writer](inout self, inout writer: W) raises -> Int64:
    #     var write_count = writer.write(self.buffer.buf)
    #     # if write_count > len(self.buffer.buf):
    #     #     raise Error("std.Reader.write_to: invalid Write count")

    #     # if write_count != len(self.buffer.buf):
    #     #     raise Error(io.ErrShortWrite)

    #     return write_count
