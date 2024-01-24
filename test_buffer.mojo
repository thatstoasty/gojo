from gojo.bytes.buffer import new_buffer_string

fn main() raises:
    var buf = new_buffer_string("Hello")
    let world = String(" World!")._buffer

    # idk why but new bytes aren't being added
    for i in range(world.size):
        let byte = world[i]
        if byte != 0:
            _ = buf.write_byte(world[i])
    print(buf.string())
