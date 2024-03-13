from gojo.builtins import Bytes
from gojo.bytes import new_reader


fn main() raises:
    var buf = Bytes("Hello")
    var dest = Bytes(16)

    var reader = new_reader(buf)
    var n = reader.read(dest)
    print(dest)