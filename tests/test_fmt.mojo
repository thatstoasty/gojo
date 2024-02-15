import fmt
from memory.unsafe import bitcast, AddressSpace

fn to_bytes(s: String) -> DynamicVector[UInt8]:
    # TODO: Len of runes can be longer than one byte
    var b = DynamicVector[UInt8](len(s))
    for i in range(len(s)):
        b.append(ord((s[i])))
    return b


fn printf(formatting_options: String, text: String) raises:
    var formatting_options_copy = formatting_options
    var formatting_options_copy_ptr = formatting_options_copy._as_ptr()
    var formatting_options_ptr = formatting_options_copy_ptr._as_scalar_pointer().bitcast[UInt8]()

    var text_copy = text
    var text_ptr = text_copy._steal_ptr()
    let bytes_written = fmt.printf(formatting_options_ptr, text_ptr)

    if bytes_written == -1:
        raise Error("printf failed to write bytes to stdout.")


fn main() raises:
    printf("%s", "Hello, World!\n")