from tests.wrapper import MojoTest
from gojo.fmt import sprintf


fn test_sprintf() raises:
    var test = MojoTest("Testing sprintf")
    var s = sprintf(
        (
            "Hello, %s. I am %d years old. More precisely, I am %f years old. It is %t"
            " that I like Mojo!"
        ),
        String("world"),
        29,
        Float64(29.5),
        True,
    )
    test.assert_equal(
        s,
        (
            "Hello, world. I am 29 years old. More precisely, I am 29.5 years old. It"
            " is True that I like Mojo!"
        ),
    )


fn main() raises:
    test_sprintf()
