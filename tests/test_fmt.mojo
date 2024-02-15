import fmt


fn to_bytes(s: String) -> DynamicVector[UInt8]:
    # TODO: Len of runes can be longer than one byte
    var b = DynamicVector[UInt8](len(s))
    for i in range(len(s)):
        b.append(ord((s[i])))
    return b


fn printf(formatting_options: String, text: String) -> Int32:
    var formatting_options_copy = formatting_options
    # var formatting_options_ptr = formatting_options_copy._steal_ptr()
    var formatting_options_ptr: Pointer[UInt8] = to_bytes(formatting_options).data.value

    # var text_copy = text
    # var text_ptr = text_copy._steal_ptr()
    return fmt.printf(formatting_options_ptr, text._as_ptr())


fn main():
    _ = printf("%s | %s", "Hello, World!\n")