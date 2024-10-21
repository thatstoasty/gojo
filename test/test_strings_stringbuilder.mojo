from gojo.strings import StringBuilder
import testing


def test_write():
    # Create a string from the builder by writing strings to it.
    builder = StringBuilder()

    for _ in range(3):
        _ = builder.write("Lorem ipsum dolor sit amet ")

    testing.assert_equal(
        str(builder),
        "Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet ",
    )


def test_big_write():
    # Create a string from the builder by writing strings to it.
    builder = StringBuilder(capacity=1)

    _ = builder.write("Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet")

    testing.assert_equal(
        str(builder),
        "Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet",
    )


def test_write_string():
    # Create a string from the builder by writing bytes to it.
    builder = StringBuilder()
    _ = builder.write("Hello")
    testing.assert_equal(str(builder), "Hello")


def test_write_byte():
    # Create a string from the builder by writing bytes to it.
    builder = StringBuilder()
    _ = builder.write_byte(ord("H"))
    testing.assert_equal(str(builder), "H")
