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
struct stdin:
    """A read only file handle to the stdin stream."""

    alias file_descriptor = 0
    alias mode = "r"
    var handle: UnsafePointer[NoneType]

    @always_inline
    fn __init__(inout self):
        """Creates a file handle to the stdin stream."""
        var handle: UnsafePointer[NoneType]

        @parameter
        if os_is_windows():
            handle = external_call["_fdopen", UnsafePointer[NoneType]](
                _dup(Self.file_descriptor), Self.mode.unsafe_ptr()
            )
        else:
            handle = external_call["fdopen", UnsafePointer[NoneType]](
                _dup(Self.file_descriptor), Self.mode.unsafe_ptr()
            )
        self.handle = handle

    @always_inline
    fn readline(self) -> String:
        var buffer = UnsafePointer[UInt8]()
        var bytes_read = external_call[
            "getline", Int, UnsafePointer[UnsafePointer[UInt8]], UnsafePointer[UInt32], UnsafePointer[NoneType]
        ](UnsafePointer(buffer), UnsafePointer(UInt32(0)), self.handle)
        return String(buffer, int(bytes_read))

    @always_inline
    fn read_until_delimiter(self, delimiter: String) -> String:
        var buffer = UnsafePointer[UInt8]()
        var bytes_read = external_call[
            "getdelim", Int, UnsafePointer[UnsafePointer[UInt8]], UnsafePointer[UInt32], Int, UnsafePointer[NoneType]
        ](UnsafePointer(buffer), UnsafePointer(UInt32(0)), ord(delimiter), self.handle)
        return String(buffer, int(bytes_read))

    @always_inline
    fn read(self, buffer: UnsafePointer[UInt8], size: Int) -> String:
        var bytes_read = 0
        while bytes_read < size:
            var byte = external_call["fgetc", Int, UnsafePointer[NoneType]](self.handle)
            if byte == -1:
                break
            buffer[bytes_read] = UInt8(byte)
            bytes_read += 1
        buffer[bytes_read] = 0
        bytes_read += 1
        return String(buffer, int(bytes_read))

    @always_inline
    fn close(self):
        _ = external_call["fclose", Int32](self.handle)

    @always_inline
    fn __del__(owned self):
        self.close()

    @always_inline
    fn __enter__(self) -> Self:
        return self

    @always_inline
    fn __exit__(self):
        """Closes the file handle."""
        self.close()


fn input(prompt: String = "") -> String:
    if prompt != "":
        print(prompt, end="")
    return stdin().readline()


fn main() raises:
    # var user_input = input("What's your name?")
    # print(user_input)
    # print(stdin().read_until_delimiter("c"))
    var buf = UnsafePointer[UInt8].alloc(4)
    print(stdin().read(buf, 4))
