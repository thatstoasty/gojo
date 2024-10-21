from collections import InlineArray
from utils import StringSlice, Span
from memory import memcpy, UnsafePointer


struct StringBuilder[growth_factor: Float32 = 2](
    Writer,
    Writable,
    AsBytes,
    Stringable,
    Sized,
):
    """
    A string builder class that allows for efficient string management and concatenation.
    This class is useful when you need to build a string by appending multiple strings
    together. The performance increase is not linear. Compared to string concatenation,
    I've observed around 20-30x faster for writing and rending ~4KB and up to 400x-500x
    for ~4MB. This is because it avoids the overhead of creating and destroying many
    intermediate strings and performs memcpy operations.

    The result is a more efficient when building larger string concatenations. It
    is generally not recommended to use this class for small concatenations such as
    a few strings like `a + b + c + d` because the overhead of creating the string
    builder and appending the strings is not worth the performance gain.

    Example:
    ```mojo
    from gojo.strings import StringBuilder

    var sb = StringBuilder()
    sb.write("Hello ")
    sb.write("World!")

    print(str(sb)) # Hello World!
    ```
    """

    var _data: UnsafePointer[Byte]
    """The internal buffer that holds the string data."""
    var _size: Int
    """The current size of the string builder."""
    var _capacity: Int
    """The current maximum capacity of the string builder."""

    fn __init__(inout self, *, capacity: Int = 4096):
        """Creates a new string builder with the given capacity.

        Args:
            capacity: The initial capacity of the string builder. The default is 4096.
        """
        constrained[growth_factor >= 1.25]()
        self._data = UnsafePointer[Byte]().alloc(capacity)
        self._size = 0
        self._capacity = capacity

    fn __moveinit__(inout self, owned other: Self):
        self._data = other._data
        self._size = other._size
        self._capacity = other._capacity
        other._data = UnsafePointer[Byte]()
        other._size = 0
        other._capacity = 0

    fn __del__(owned self):
        if self._data:
            self._data.free()

    fn __len__(self) -> Int:
        """Returns the length of the string builder."""
        return self._size

    fn as_bytes(ref [_]self) -> Span[Byte, __origin_of(self)]:
        """Returns the internal data as a Span[Byte]."""
        return Span[Byte, __origin_of(self)](unsafe_ptr=self._data, len=self._size)

    fn as_string_slice(ref [_]self) -> StringSlice[__origin_of(self)]:
        """Return a StringSlice view of the data owned by the builder.

        Returns:
            The string representation of the string builder. Returns an empty string if the string builder is empty.
        """
        return StringSlice[__origin_of(self)](unsafe_from_utf8_ptr=self._data, len=self._size)

    fn __str__(self) -> String:
        """Converts the string builder to a string.

        Returns:
            The string representation of the string builder. Returns an empty
            string if the string builder is empty.
        """
        return String.write(self)

    fn consume(inout self, reuse: Bool = False) -> String:
        """
        Transfers the string builder's data to a string and resets the string builder. Effectively consuming the string builder.

        Args:
            reuse: If `True`, a new buffer will be allocated with the same capacity as the previous buffer.

        Returns:
          The string representation of the string builder. Returns an empty string if the buffer is empty.
        """
        var bytes = List[Byte, True](unsafe_pointer=self._data, size=self._size, capacity=self._capacity)
        bytes.append(0)
        var result = String(bytes^)

        if reuse:
            self._data = UnsafePointer[Byte].alloc(self._capacity)
        else:
            self._data = UnsafePointer[Byte]()
        self._size = 0
        return result

    fn _resize(inout self, capacity: Int) -> None:
        """Resizes the string builder buffer.

        Args:
            capacity: The new capacity of the string builder buffer.
        """
        var new_data = UnsafePointer[Byte]().alloc(capacity)
        memcpy(new_data, self._data, self._size)
        self._data.free()
        self._data = new_data
        self._capacity = capacity

    fn _resize_if_needed(inout self, byte_count: Int) -> None:
        """Resizes the buffer if the bytes to add exceeds the current capacity.

        Args:
            byte_count: The number of bytes to add to the buffer.
        """
        # TODO: Handle the case where new_capacity is greater than MAX_INT. It should panic.
        if byte_count > self._capacity - self._size:
            var new_capacity = self._capacity * 2
            if new_capacity < self._capacity + byte_count:
                new_capacity = self._capacity + byte_count
            self._resize(new_capacity)

    fn write_to[W: Writer](self, inout writer: W):
        writer.write(self.as_string_slice())

    fn write_byte(inout self, byte: Byte):
        """Appends a byte to the builder buffer.

        Args:
            byte: The byte to append.
        """
        self._resize_if_needed(1)
        self._data[self._size] = byte
        self._size += 1

    @always_inline
    fn write_bytes(inout self, bytes: Span[Byte, _]) -> None:
        """
        Write a `Span[Byte]` to this `Writer`.
        Args:
            bytes: The string slice to write to this Writer. Must NOT be
              null-terminated.
        """
        if len(bytes) == 0:
            return

        self._resize_if_needed(len(bytes))
        memcpy(self._data.offset(self._size), bytes._data, len(bytes))
        self._size += len(bytes)

    fn write[*Ts: Writable](inout self, *args: *Ts) -> None:
        """Write data to the `StringBuilder`."""

        @parameter
        fn write_arg[T: Writable](arg: T):
            arg.write_to(self)

        args.each[write_arg]()
