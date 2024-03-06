from time import now
from tests.wrapper import MojoTest
from gojo.strings import StringBuilder


fn test_string_builder() raises:
    var test = MojoTest("Testing StringBuilder")
    # Create a string from the buffer
    var builder = StringBuilder()

    for i in range(3):
        builder.write_string("Lorem ipsum dolor sit amet ")

    test.assert_equal(
        str(builder),
        (
            "Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor"
            " sit amet "
        ),
    )


fn main() raises:
    test_string_builder()
