from ..external.libc import fopen, fread, fclose, fwrite, strnlen
from ..builtins._bytes import Bytes, Byte, to_string, to_bytes
from ..builtins import copy
from .traits import Writer, Reader, ReadSeekCloser


alias c_char = UInt8
alias FILE = UInt64
alias BUF_SIZE = 4096


fn to_char_ptr(s: String) -> Pointer[c_char]:
    """Only ASCII-based strings."""
    let ptr = Pointer[c_char]().alloc(len(s) + 1)
    for i in range(len(s)):
        ptr.store(i, ord(s[i]))
    ptr.store(len(s), ord("\0"))
    return ptr


@value
struct File(Writer, Reader):
    var handle: Pointer[UInt64]
    var fname: Pointer[c_char]
    var mode: Pointer[c_char]

    fn __init__(inout self, filename: String, mode: StringLiteral):
        let fname = to_char_ptr(filename)

        let mode_cstr = to_char_ptr(mode)
        let handle = fopen(fname, mode_cstr)

        self.fname = fname
        self.mode = mode_cstr
        self.handle = handle

    fn __bool__(self) -> Bool:
        return self.handle.__bool__()

    fn __del__(owned self):
        if self.handle:
            pass
            # TODO: uncomment when external_call resolution bug is fixed
            # let c = fclose(self.handle)
            # if c != 0:
            #     print("Failed to close file")
        if self.fname:
            self.fname.free()
        if self.mode:
            self.mode.free()

    fn __moveinit__(inout self, owned other: Self):
        self.fname = other.fname
        self.mode = other.mode
        self.handle = other.handle
        other.handle = Pointer[FILE]()
        other.fname = Pointer[c_char]()
        other.mode = Pointer[c_char]()

    fn do_nothing(self):
        pass

    fn read(inout self, inout dest: Bytes) raises -> Int:
        return fread(
            dest._vector.data.value, sizeof[UInt8](), BUF_SIZE, self.handle
        ).to_int()

    fn write(inout self, src: Bytes) raises -> Int:
        return fwrite(
            src._vector.data.value, sizeof[UInt8](), len(src), self.handle
        ).to_int()

    fn write_all(inout self, src: Bytes) raises:
        var index = 0
        while index != len(src):
            index += self.write(src)

    # fn write_byte(self, byte: UInt8) raises:
    #     let buf = Buffer[1, DType.uint8]().stack_allocation()
    #     buf[0] = byte
    #     self.write_all(buf)

    # fn write_byte_n_times(self, byte: UInt8, n: Int) raises:
    #     var bytes = StaticTuple[256, UInt8]()
    #     let bytes_ptr = DTypePointer[DType.uint8](
    #         Pointer.address_of(bytes).bitcast[UInt8]()
    #     )
    #     memset[DType.uint8](
    #         bytes_ptr,
    #         byte,
    #         256,
    #     )
    #     var remaining = n
    #     while remaining > 0:
    #         let to_write = min(remaining, bytes.__len__())
    #         self.write_all(Buffer[Dim(), DType.uint8](bytes_ptr, to_write))
    #         remaining -= to_write


struct FileWrapper(Movable, ReadSeekCloser, Writer):
    var handle: FileHandle

    fn __init__(inout self, path: String, mode: StringLiteral) raises:
        self.handle = open(path, mode)

    fn __moveinit__(inout self, owned existing: Self):
        self.handle = existing.handle ^

    fn close(inout self) raises:
        self.handle.close()

    fn read(inout self, inout dest: Bytes) raises -> Int:
        # Pretty hacky way to force the filehandle read into the defined trait.
        # Call filehandle.read, convert result into bytes, copy into dest (overwrites the first X elements), then return a slice minus all the extra 0 filled elements.
        let result_bytes = to_bytes(self.handle.read(dest._vector.capacity))
        let elements_copied = copy(dest, result_bytes)
        dest = dest[:elements_copied]
        return elements_copied

    fn read_bytes(inout self, size: Int64) raises -> Tensor[DType.int8]:
        return self.handle.read_bytes(size)

    fn read_bytes(inout self) raises -> Tensor[DType.int8]:
        return self.handle.read_bytes()

    fn seek(inout self, offset: Int64, whence: Int = 0) raises -> Int:
        return int(self.handle.seek(offset.cast[DType.uint64]()))

    fn write(inout self, src: Bytes) raises -> Int:
        self.handle.write(to_string(src))
        return len(src)