from time import now
from testing import testing
from gojo.strings import StringBuilder


fn test_string_builder() raises:
    print("Testing StringBuilder")
    # Create a string from the buffer
    var builder = StringBuilder()

    for i in range(3):
        builder.write_string("Lorem ipsum dolor sit amet ")
    
    testing.assert_equal(str(builder), "Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet ")


fn strings_tests() raises:
    test_string_builder()
