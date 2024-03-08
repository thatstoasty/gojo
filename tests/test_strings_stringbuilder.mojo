from tests.wrapper import MojoTest
from gojo.strings import StringBuilder
from gojo.builtins import Bytes


fn test_string_builder() raises:
    var test = MojoTest("Testing strings.StringBuilder")

    # Create a string from the builder by writing strings to it.
    var builder = StringBuilder()

    for i in range(3):
        _ = builder.write_string("Lorem ipsum dolor sit amet ")

    test.assert_equal(
        str(builder),
        (
            "Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor"
            " sit amet "
        ),
    )

    # Create a string from the builder by writing bytes to it.
    builder = StringBuilder()
    _ = builder.write(Bytes("Hello"))
    _ = builder.write_byte(32)
    test.assert_equal(str(builder), "Hello ")


fn main() raises:
    test_string_builder()
