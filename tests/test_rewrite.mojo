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
        let written = min(len(dest) - dest_index, end - start)
        print("written", written)

        # 1. Fill buffer with data from file.
        # 2. Next loop, copy data from temp buffer to destination buffer,
        # 3. Next loop, if buffer is empty, fill it again.
        # 4. At the end of the loop, advance the start and dest_index by the number of bytes written to keep track of position.
        print(dest.data.offset(dest_index).load())
        memcpy(dest.data.offset(dest_index), data.offset(start), written)
        print("memcpy done")

        # buf empty, fill it.
        if written == 0:
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
    var buffer = Buffer[256, Byte]().stack_allocation()
    let bytes_read = read(buffer)
    let p = buffer.data._as_scalar_pointer().bitcast[__mlir_type.`!pop.scalar<si8>`]().address
    let s = StringRef(p, bytes_read)
    print(s)
    # StringRef(, bytes_read)