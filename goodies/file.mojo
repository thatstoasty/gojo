import gojo.io
from gojo.syscall import FileDescriptorBase


struct FileWrapper(FileDescriptorBase, io.ByteReader):
    var handle: FileHandle

    fn __init__(inout self, path: String, mode: String) raises:
        self.handle = open(path, mode)

    fn __moveinit__(inout self, owned existing: Self):
        self.handle = existing.handle^

    fn __del__(owned self):
        var err = self.close()
        if err:
            # TODO: __del__ can't raise, but there should be some fallback.
            print(str(err))

    fn close(inout self) -> Error:
        try:
            self.handle.close()
        except e:
            return e

        return Error()

    fn read(inout self, inout dest: List[UInt8]) -> (Int, Error):
        # Pretty hacky way to force the filehandle read into the defined trait.
        var bytes_to_read = dest.capacity - len(dest)
        var result: List[UInt8]
        try:
            result = self.handle.read_bytes(bytes_to_read)
        except e:
            return 0, e

        var bytes_read = len(result)
        print(
            "bytes read",
            bytes_read,
            "bytes to read",
            bytes_to_read,
            "dest size",
            len(dest),
            "dest capacity",
            dest.capacity,
        )
        if bytes_read == 0:
            return 0, Error(io.EOF)
        for i in range(len(result)):
            print("result[", i, "]", result[i])

        memcpy(DTypePointer[DType.uint8](dest.unsafe_ptr()).offset(dest.size), result.unsafe_ptr(), bytes_read)
        dest.size += bytes_read
        print("dest size", dest.size)
        for i in range(len(dest)):
            print("dest[", i, "]", dest[i])

        if bytes_read < bytes_to_read:
            return bytes_read, Error(io.EOF)

        return bytes_read, Error()

    fn read(inout self, inout dest: List[UInt8], size: Int) -> (Int, Error):
        # Pretty hacky way to force the filehandle read into the defined trait.
        var result: List[UInt8]
        try:
            result = self.handle.read_bytes(size)
        except e:
            return 0, e

        var bytes_read = len(result)
        if bytes_read == 0:
            return 0, Error(io.EOF)

        memcpy(DTypePointer(dest.unsafe_ptr()).offset(len(dest)), result.unsafe_ptr(), bytes_read)
        dest.size += bytes_read

        if bytes_read < size:
            return bytes_read, Error(io.EOF)

        return bytes_read, Error()

    fn read_all(inout self) -> (List[UInt8], Error):
        var bytes = List[UInt8](capacity=io.BUFFER_SIZE)
        while True:
            var temp = List[UInt8](capacity=io.BUFFER_SIZE)
            _ = self.read(temp, io.BUFFER_SIZE)

            # If new bytes will overflow the result, resize it.
            if len(bytes) + len(temp) > bytes.capacity:
                bytes.reserve(bytes.capacity * 2)
            bytes.extend(temp)

            if len(temp) < io.BUFFER_SIZE:
                return bytes, Error(io.EOF)

    fn read_byte(inout self) -> (UInt8, Error):
        try:
            var byte = self.read_bytes(1)[0]
            return byte, Error()
        except e:
            return UInt8(0), Error(str(e))

    fn read_bytes(inout self, size: Int = -1) raises -> List[UInt8]:
        return self.handle.read_bytes(size)

    fn stream_until_delimiter(inout self, inout dest: List[UInt8], delimiter: UInt8, max_size: Int) raises:
        var byte: UInt8
        var err: Error
        for _ in range(max_size):
            byte, err = self.read_byte()
            if byte == delimiter:
                return
            dest.append(byte)
        raise Error("Stream too long")

    fn seek(inout self, offset: Int64, whence: Int = 0) -> (Int64, Error):
        try:
            var position = self.handle.seek(UInt64(offset))
            return Int64(position), Error()
        except e:
            return Int64(0), Error(str(e))

    fn write(inout self, src: Span[UInt8]) -> (Int, Error):
        try:
            self.handle.write(data=src.unsafe_ptr())
            return len(src), Error(io.EOF)
        except e:
            return 0, Error(str(e))
