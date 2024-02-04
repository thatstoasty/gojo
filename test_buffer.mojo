from gojo.bytes.buffer import new_buffer_string
from gojo.bytes.bytes import to_bytes

fn main() raises:
    var a: String = "Hello"
    var buf = new_buffer_string(a)
    let world = to_bytes(String(" World!"))

    # idk why but new bytes aren't being added
    for i in range(len(world)):
        let byte = world[i]
        if byte != 0:
            _ = buf.write_byte(world[i])
    print(buf.string())
