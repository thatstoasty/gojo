from gojo.fmt import sprintf, printf
import testing


def test_sprintf():
    s = sprintf(
        "Hello, %s. I am %d years old. More precisely, I am %f years old. It is %t that I like Mojo!",
        String("world"),
        29,
        Float64(29.5),
        True,
    )
    testing.assert_equal(
        s,
        "Hello, world. I am 29 years old. More precisely, I am 29.5 years old. It is True that I like Mojo!",
    )

    s = sprintf("Hello %s", List[UInt8, True]("world".as_bytes()))
    testing.assert_equal(s, "Hello world")


def test_printf():
    printf(
        "Hello, %s. I am %d years old. More precisely, I am %f years old. It is %t that I like Mojo!",
        String("world"),
        29,
        Float64(29.5),
        True,
    )
