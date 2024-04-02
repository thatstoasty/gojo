from tests.wrapper import MojoTest
from gojo.strings import StringBuilder
from gojo.builtins import Byte


fn test_write_string() raises:
    var test = MojoTest("Testing strings.StringBuilder.write_string")

    # Create a string from the builder by writing strings to it.
    var builder = StringBuilder()

    for i in range(3):
        _ = builder.write_string("Lorem ipsum dolor sit amet ")

    test.assert_equal(
        String(builder),
        (
            "Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor"
            " sit amet "
        ),
    )


fn test_write() raises:
    var test = MojoTest("Testing strings.StringBuilder.write")

    # Create a string from the builder by writing bytes to it.
    var builder = StringBuilder()
    _ = builder.write(String("Hello").as_bytes())
    test.assert_equal(String(builder), "Hello")


fn test_write_byte() raises:
    var test = MojoTest("Testing strings.StringBuilder.write_byte")

    # Create a string from the builder by writing bytes to it.
    var builder = StringBuilder()
    _ = builder.write_byte(32)
    test.assert_equal(String(builder), " ")


fn main() raises:
    test_write_string()
    test_write()
    test_write_byte()
