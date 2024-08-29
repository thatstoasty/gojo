from gojo.strings import StringBuilder
import testing


def test_write_string():
    # var test = MojoTest("Testing strings.StringBuilder.write_string")

    # Create a string from the builder by writing strings to it.
    var builder = StringBuilder()

    for _ in range(3):
        _ = builder.write_string("Lorem ipsum dolor sit amet ")

    testing.assert_equal(
        str(builder),
        "Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet ",
    )


def test_big_write():
    # var test = MojoTest("Testing strings.StringBuilder.write_string with big Write")

    # Create a string from the builder by writing strings to it.
    var builder = StringBuilder(capacity=1)

    _ = builder.write_string("Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet")

    testing.assert_equal(
        str(builder),
        "Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet",
    )


def test_write():
    # var test = MojoTest("Testing strings.StringBuilder.write")

    # Create a string from the builder by writing bytes to it.
    var builder = StringBuilder()
    _ = builder.write(String("Hello").as_bytes_slice())
    testing.assert_equal(str(builder), "Hello")


def test_write_byte():
    # var test = MojoTest("Testing strings.StringBuilder.write_byte")

    # Create a string from the builder by writing bytes to it.
    var builder = StringBuilder()
    _ = builder.write_byte(ord("H"))
    testing.assert_equal(str(builder), "H")


def main():
    test_write_string()
    test_write()
    test_write_byte()
    test_big_write()
