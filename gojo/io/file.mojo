from ..builtins import Bytes, Byte, copy, Result, WrappedError
from .io import BUFFER_SIZE


struct FileWrapper(io.ReadWriteSeeker, io.ByteReader):
    var handle: FileHandle

    fn __init__(inout self, path: String, mode: StringLiteral) raises:
        self.handle = open(path, mode)

    fn __moveinit__(inout self, owned existing: Self):
        self.handle = existing.handle ^

    fn __del__(owned self):
        try:
            self.close()
        except Error:
            # TODO: __del__ can't raise, but there should be some fallback.
            print("Failed to close the file.")

    fn close(inout self) raises:
        self.handle.close()

    fn read(inout self, inout dest: Bytes) -> Result[Int]:
        # Pretty hacky way to force the filehandle read into the defined trait.
        # Call filehandle.read, convert result into bytes, copy into dest (overwrites the first X elements), then return a slice minus all the extra 0 filled elements.
        var result: String = ""
        try:
            var result = self.handle.read(dest.available())
        except e:
            return Result(0, WrappedError(e))
        
        if len(result) == 0:
            return Result(0, WrappedError(io.EOF))

        var bytes_result = Bytes(result)
        var elements_copied = copy(dest, bytes_result[: len(bytes_result)])
        dest = dest[:elements_copied]
        return elements_copied

    fn read(inout self, inout dest: Bytes, size: Int64) -> Result[Int]:
        # Pretty hacky way to force the filehandle read into the defined trait.
        # Call filehandle.read, convert result into bytes, copy into dest (overwrites the first X elements), then return a slice minus all the extra 0 filled elements.
        var result: String = ""
        try:
            var result = self.handle.read(size)
        except e:
            return Result(0, WrappedError(e))
        
        if len(result) == 0:
            return Result(0, WrappedError(io.EOF))

        var bytes_result = Bytes(result)
        var elements_copied = copy(dest, bytes_result[: len(bytes_result)])
        dest = dest[:elements_copied]
        return elements_copied

    fn read_all(inout self) -> Result[Bytes]:
        var bytes = Bytes(BUFFER_SIZE)
        while True:
            var temp = Bytes(BUFFER_SIZE)
            _ = self.read(temp, BUFFER_SIZE)

            # If new bytes will overflow the result, resize it.
            if len(bytes) + len(temp) > bytes.size():
                bytes.resize(bytes.size() * 2)
            bytes += temp

            if len(temp) < BUFFER_SIZE:
                return Result(bytes, WrappedError(io.EOF))

        return Result(bytes)

    fn read_byte(inout self) -> Result[Byte]:
        try:
            var byte = self.read_bytes(1)[0]
            return Result(byte)
        except e:
            return Result(Int8(0), WrappedError(e))

    fn read_bytes(inout self, size: Int64) raises -> Tensor[DType.int8]:
        return self.handle.read_bytes(size)

    fn read_bytes(inout self) raises -> Tensor[DType.int8]:
        return self.handle.read_bytes()

    fn stream_until_delimiter(
        inout self, inout dest: Bytes, delimiter: Int8, max_size: Int
    ) raises:
        for i in range(max_size):
            var byte = self.read_byte().unwrap()
            if byte == delimiter:
                return
            dest.append(byte)
        raise Error("Stream too long")

    fn seek(inout self, offset: Int64, whence: Int = 0) -> Result[Int64]:
        try:
            var position = self.handle.seek(offset.cast[DType.uint64]())
            return position.cast[DType.int64]()
        except e:
            return Result(Int64(0), WrappedError(e))

    fn write(inout self, src: Bytes) -> Result[Int]:
        try:
            self.handle.write(String(src))
            return len(src)
        except e:
            return Result(0, WrappedError(e))
