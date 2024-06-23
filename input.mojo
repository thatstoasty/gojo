from builtin.io import _dup


fn fgetc(stream: UnsafePointer[NoneType]) -> Int32:
    return external_call["fgetc", Int32, UnsafePointer[NoneType]](stream)


fn fgets(buffer: UnsafePointer[UInt8], number_of_bytes: Int32, stream: UnsafePointer[NoneType]) -> UnsafePointer[UInt8]:
    """Function: char *fgets(char *str, int n, FILE *stream)."""
    return external_call["fgets", UnsafePointer[UInt8], UnsafePointer[UInt8], Int32, UnsafePointer[NoneType]](
        buffer, number_of_bytes, stream
    )


fn getline(
    lineptr: UnsafePointer[UnsafePointer[UInt8]], number_of_bytes: UnsafePointer[Int32], stream: UnsafePointer[NoneType]
) -> Int32:
    """Function: ssize_t getline(char **restrict lineptr, size_t *restrict n, FILE *restrict stream)."""
    return external_call[
        "getline", Int32, UnsafePointer[UnsafePointer[UInt8]], UnsafePointer[Int32], UnsafePointer[NoneType]
    ](lineptr, number_of_bytes, stream)


@value
@register_passable("trivial")
struct _fdopen:
    alias STDIN = 0
    var handle: UnsafePointer[NoneType]

    fn __init__(inout self, stream_id: FileDescriptor):
        """Creates a file handle to the stdout/stderr stream.

        Args:
            stream_id: The stream id
        """
        alias mode = "r"
        var handle: UnsafePointer[NoneType]

        @parameter
        if os_is_windows():
            handle = external_call["_fdopen", UnsafePointer[NoneType]](_dup(stream_id.value), mode.unsafe_ptr())
        else:
            handle = external_call["fdopen", UnsafePointer[NoneType]](_dup(stream_id.value), mode.unsafe_ptr())
        self.handle = handle

    fn __enter__(self) -> Self:
        return self

    fn __exit__(self):
        """Closes the file handle."""
        _ = external_call["fclose", Int32](self.handle)


alias STDIN = 0


fn input(prompt: String = "") -> String:
    if prompt != "":
        print(prompt, end="")
    var buf = UnsafePointer[UInt8]()
    var bytes_read: Int32
    with _fdopen(STDIN) as f:
        bytes_read = getline(UnsafePointer(buf), UnsafePointer(Int32(0)), f.handle)
    return String(buf, int(bytes_read))


fn main() raises:
    var user_input = input("What's your name?")
    print(user_input)
