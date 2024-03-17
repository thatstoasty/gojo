from ..builtins import Bytes, Byte, copy
from .io import BUFFER_SIZE


struct FileWrapper(io.ReadWriteSeeker, io.ByteReader):
    var handle: FileHandle
    var path: String
    var mode: String

    fn __init__(inout self, path: String, mode: String) raises:
        self.handle = open(path, mode)
        self.path = path
        self.mode = mode

    fn __moveinit__(inout self, owned existing: Self):
        self.handle = existing.handle ^
        self.path = existing.path ^
        self.mode = existing.mode ^
    
    fn __enter__(inout self) raises -> Self:
        self.close()
        return Self(self.path, self.mode)
    
    fn __exit__(inout self) raises:
        self.close()

    fn __del__(owned self):
        try:
            self.close()
        except e:
            # TODO: __del__ can't raise, but there should be some fallback.
            print("Failed to close the file.")

    fn close(inout self) raises:
        self.handle.close()

    fn read(inout self, inout dest: Bytes) raises -> Int:
        # Pretty hacky way to force the filehandle read into the defined trait.
        # Call filehandle.read, convert result into bytes, copy into dest (overwrites the first X elements), then return a slice minus all the extra 0 filled elements.
        var result = self.handle.read(dest.available())
        if len(result) == 0:
            raise Error(io.EOF)

        var bytes_result = Bytes(result)
        var elements_copied = copy(dest, bytes_result[: len(bytes_result)])
        dest = dest[:elements_copied]
        return elements_copied

    fn read(inout self, inout dest: Bytes, size: Int64) raises -> Int:
        # Pretty hacky way to force the filehandle read into the defined trait.
        # Call filehandle.read, convert result into bytes, copy into dest (overwrites the first X elements), then return a slice minus all the extra 0 filled elements.
        var result = self.handle.read(size)
        if len(result) == 0:
            raise Error(io.EOF)

        var bytes_result = Bytes(result)
        var elements_copied = copy(dest, bytes_result[: len(bytes_result)])
        dest = dest[:elements_copied]
        return elements_copied

    fn read_all(inout self) raises -> Bytes:
        var result = Bytes(BUFFER_SIZE)
        while True:
            try:
                var temp = Bytes(BUFFER_SIZE)
                _ = self.read(temp, BUFFER_SIZE)

                # If new bytes will overflow the result, resize it.
                if len(result) + len(temp) > result.size():
                    result.resize(result.size() * 2)
                result += temp

                if len(temp) < BUFFER_SIZE:
                    raise Error(io.EOF)
            except e:
                if str(e) == "EOF":
                    break
                raise
        return result

    fn read_byte(inout self) raises -> Byte:
        return self.read_bytes(1)[0]

    fn read_bytes(inout self, size: Int64) raises -> Tensor[DType.int8]:
        return self.handle.read_bytes(size)

    fn read_bytes(inout self) raises -> Tensor[DType.int8]:
        return self.handle.read_bytes()

    fn stream_until_delimiter(
        inout self, inout dest: Bytes, delimiter: Int8, max_size: Int
    ) raises:
        for i in range(max_size):
            var byte = self.read_byte()
            if byte == delimiter:
                return
            dest.append(byte)
        raise Error("Stream too long")

    fn seek(inout self, offset: Int64, whence: Int = 0) raises -> Int64:
        return self.handle.seek(offset.cast[DType.uint64]()).cast[DType.int64]()

    fn write(inout self, src: Bytes) raises -> Int:
        self.handle.write(String(src))
        return len(src)
