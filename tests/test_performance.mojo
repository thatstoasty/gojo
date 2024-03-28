from time import now
from gojo.strings import StringBuilder
from gojo.bytes import buffer
from goodies import STDWriter


fn test_string_builder() raises:
    print("Testing string builder performance")
    # Create a string from the buffer
    var builder = StringBuilder()
    for i in range(100):
        _ = builder.write_string(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod"
            " tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim"
            " veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea"
            " commodo consequat. Duis aute irure dolor in reprehenderit in voluptate"
            " velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint"
            " occaecat cupidatat non proident, sunt in culpa qui officia deserunt"
            " mollit anim id est laborum."
        )

    var builder_start_time = now()
    var output = str(builder)
    var builder_execution_time = now() - builder_start_time

    # Create a string using the + operator
    print("Testing string concatenation performance")
    var vec = List[String]()
    for i in range(100):
        vec.append(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod"
            " tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim"
            " veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea"
            " commodo consequat. Duis aute irure dolor in reprehenderit in voluptate"
            " velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint"
            " occaecat cupidatat non proident, sunt in culpa qui officia deserunt"
            " mollit anim id est laborum."
        )

    var concat_start_time = now()
    var concat_output: String = ""
    for i in range(len(vec)):
        concat_output += vec[i]
    var concat_execution_time = now() - concat_start_time

    # Create a string using a bytes buffer
    print("Testing bytes buffer performance")
    var buf = buffer.new_buffer()
    for i in range(100):
        _ = buf.write_string(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod"
            " tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim"
            " veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea"
            " commodo consequat. Duis aute irure dolor in reprehenderit in voluptate"
            " velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint"
            " occaecat cupidatat non proident, sunt in culpa qui officia deserunt"
            " mollit anim id est laborum."
        )

    var buffer_start_time = now()
    var buffer_output = str(buf)
    print(len(buffer_output))
    var buffer_execution_time = now() - buffer_start_time

    print("StringBuilder:", "(", builder_execution_time, "ns)")
    print("String concat:", "(", concat_execution_time, "ns)")
    print("Bytes Buffer:", "(", buffer_execution_time, "ns)")
    print(
        "Performance difference: ",
        str(concat_execution_time - builder_execution_time) + "ns",
        ": StringBuilder is ",
        str(concat_execution_time // builder_execution_time) + "x faster",
        ": Bytes Buffer is ",
        str(concat_execution_time // buffer_execution_time) + "x faster",
    )


fn test_std_writer_speed() raises:
    """STDWriter is roughly 6-7x faster currently."""
    var print_start_time = now()
    for i in range(1, 10000):
        print(i)
    var print_execution_time = now() - print_start_time

    # Create stdout writer
    var writer = STDWriter(1)
    var writer_start_time = now()
    for i in range(1, 10000):
        _ = writer.write_string(str(i))
    var writer_execution_time = now() - writer_start_time

    print("\n\nprint execution time (s): " + str((print_execution_time) / 1e9))
    print("writer execution time (s): " + str((writer_execution_time) / 1e9))
    print("Writer is ", str(print_execution_time // writer_execution_time) + "x faster")


fn main() raises:
    # test_std_writer_speed()
    test_string_builder()
