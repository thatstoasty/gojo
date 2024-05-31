import ..io
from ..builtins import Byte


@value
struct LegacyStringBuilder(Stringable, Sized, io.Writer, io.ByteWriter, io.StringWriter):
    """
    A string builder class that allows for efficient string management and concatenation.
    This class is useful when you need to build a string by appending multiple strings
    together. It is around 20x faster than using the `+` operator to concatenate
    strings because it avoids the overhead of creating and destroying many
    intermediate strings and performs memcopy operations.

    The result is a more efficient when building larger string concatenations. It
    is generally not recommended to use this class for small concatenations such as
    a few strings like `a + b + c + d` because the overhead of creating the string
    builder and appending the strings is not worth the performance gain.

    Example:
      ```
      from strings.builder import StringBuilder

      var sb = StringBuilder()
      sb.write_string("mojo")
      sb.write_string("jojo")
      print(sb) # mojojojo
      ```
    """

    var _vector: List[Byte]

    fn __init__(inout self, *, size: Int = 4096):
        self._vector = List[Byte](capacity=size)

    fn __str__(self) -> String:
        """
        Converts the string builder to a string.

        Returns:
          The string representation of the string builder. Returns an empty
          string if the string builder is empty.
        """
        var copy = List[Byte](self._vector)
        if copy[-1] != 0:
            copy.append(0)
        return String(copy)

    fn get_bytes(self) -> List[Byte]:
        """
        Returns a deepcopy of the byte array of the string builder.

        Returns:
          The byte array of the string builder.
        """
        return List[Byte](self._vector)

    fn get_null_terminated_bytes(self) -> List[Byte]:
        """
        Returns a deepcopy of the byte array of the string builder with a null terminator.

        Returns:
          The byte array of the string builder with a null terminator.
        """
        var copy = List[Byte](self._vector)
        if copy[-1] != 0:
            copy.append(0)

        return copy

    fn write(inout self, src: List[Byte]) -> (Int, Error):
        """
        Appends a byte array to the builder buffer.

        Args:
          src: The byte array to append.
        """
        self._vector.extend(src)
        return len(src), Error()

    fn write_byte(inout self, byte: Byte) -> (Int, Error):
        """
        Appends a byte array to the builder buffer.

        Args:
            byte: The byte array to append.
        """
        self._vector.append(byte)
        return 1, Error()

    fn write_string(inout self, src: String) -> (Int, Error):
        """
        Appends a string to the builder buffer.

        Args:
          src: The string to append.
        """
        var string_buffer = src.as_bytes()
        self._vector.extend(string_buffer)
        return len(string_buffer), Error()

    fn __len__(self) -> Int:
        """
        Returns the length of the string builder.

        Returns:
          The length of the string builder.
        """
        return len(self._vector)

    fn __getitem__(self, index: Int) -> String:
        """
        Returns the string at the given index.

        Args:
          index: The index of the string to return.

        Returns:
          The string at the given index.
        """
        return self._vector[index]

    fn __setitem__(inout self, index: Int, value: Byte):
        """
        Sets the string at the given index.

        Args:
          index: The index of the string to set.
          value: The value to set.
        """
        self._vector[index] = value


@value
struct StringBuilder[growth_factor: Float32 = 2](Stringable, Sized):
    """
    A string builder class that allows for efficient string management and concatenation.
    This class is useful when you need to build a string by appending multiple strings
    together. It is around 20-30x faster than using the `+` operator to concatenate
    strings because it avoids the overhead of creating and destroying many
    intermediate strings and performs memcopy operations.

    The result is a more efficient when building larger string concatenations. It
    is generally not recommended to use this class for small concatenations such as
    a few strings like `a + b + c + d` because the overhead of creating the string
    builder and appending the strings is not worth the performance gain.

    Example:
      ```
      from strings.builder import StringBuilder

      var sb = StringBuilder()
      sb.write_string("Hello ")
      sb.write_string("World!")
      print(sb) # Hello World!
      ```
    """

    var data: DTypePointer[DType.uint8]
    var size: Int
    var capacity: Int

    @always_inline
    fn __init__(inout self, *, capacity: Int = 4096):
        constrained[growth_factor >= 1.25]()
        self.data = DTypePointer[DType.uint8]().alloc(capacity)
        self.size = 0
        self.capacity = capacity

    @always_inline
    fn __str__(self) -> String:
        """
        Converts the string builder to a string.

        Returns:
          The string representation of the string builder. Returns an empty
          string if the string builder is empty.
        """
        var copy = DTypePointer[DType.uint8]().alloc(self.size)
        memcpy(copy, self.data, self.size)
        return StringRef(copy, self.size)

    @always_inline
    fn render(self: Reference[Self]) -> StringSlice[self.is_mutable, self.lifetime]:
        """
        Return a StringSlice view of the data owned by the builder.

        Returns:
          The string representation of the string builder. Returns an empty string if the string builder is empty.
        """
        return StringSlice[self.is_mutable, self.lifetime](unsafe_from_utf8_strref=StringRef(self[].data, self[].size))

    @always_inline
    fn __del__(owned self):
        if self.data:
            self.data.free()

    @always_inline
    fn _resize(inout self, capacity: Int) -> None:
        """
        Resizes the string builder buffer.

        Args:
          capacity: The new capacity of the string builder buffer.
        """
        var new_data = DTypePointer[DType.uint8]().alloc(capacity)
        memcpy(new_data, self.data, self.size)
        self.data.free()
        self.data = new_data
        self.capacity = capacity

        return None

    @always_inline
    fn write(inout self, src: Span[Byte]) -> (Int, Error):
        """
        Appends a byte Span to the builder buffer.

        Args:
          src: The byte array to append.
        """
        if len(src) > self.capacity - self.size:
            self._resize(int(self.capacity * growth_factor))

        memcpy(self.data.offset(self.size), src._data, len(src))
        self.size += len(src)

        return len(src), Error()

    @always_inline
    fn write_string(inout self, src: String) -> (Int, Error):
        """
        Appends a string to the builder buffer.

        Args:
          src: The string to append.
        """
        return self.write(src.as_bytes_slice())

    @always_inline
    fn __len__(self) -> Int:
        """
        Returns the length of the string builder.

        Returns:
          The length of the string builder.
        """
        return self.size
