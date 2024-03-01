from gojo.builtins._bytes import Bytes


fn main():
    var bytes = Bytes(s="hello")
    print(bytes)

    bytes.append(102)
    print(bytes)

    bytes += String(" World").as_bytes()
    print(bytes)

    var bytes2 = DynamicVector[Int8]()
    bytes2.append(104)
    bytes.extend(bytes2)
    print(bytes)