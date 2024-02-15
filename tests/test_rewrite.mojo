from memory.unsafe import DTypePointer
from memory.buffer import Buffer
from memory.memory import memcpy
from utils.list import Dim
from math import min

from std.file import FileWrapper


alias Byte = DType.uint8
alias BUF_SIZE = 4096


fn read[D: Dim](dest: Buffer[D, Byte]) raises -> Int:
    var dest_index = 0
    var data = DTypePointer[Byte]().alloc(BUF_SIZE)
    var buf = Buffer[BUF_SIZE, Byte](data)

    var start: Int = 0
    var end: Int = 0

    var reader = FileWrapper("test.txt", "r")

    while dest_index < len(dest):
        print(dest_index, len(dest))
        print("here")
        # len(dest) - dest_index = remaining bytes to be read in dest
        # end - start = ?
        var written = min(len(dest) - dest_index, end - start)
        print("written", written)

        # copies X elements from the internal buffer to the dest buffer
        # 1. write the data to the internal buffer
        # 2. update start and dest_index to the number of bytes written
        # 3. 
        memcpy(dest.data.offset(dest_index), data.offset(start), written)
        print("memcpy done")
        if written == 0:
            # buf empty, fill it
            var n = reader.read(buf)
            if n == 0:
                # reading from the unbuffered stream returned nothing
                # so we have nothing left to read.
                return dest_index
            start = 0
            end = n
        start += written
        dest_index += written
    return len(dest)


fn main() raises:
    print(read(Buffer[256, Byte]()))