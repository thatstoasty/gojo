from time import now
from gojo.strings.builder import LegacyStringBuilder, StringBuilder
from gojo.bytes import buffer
from goodies import STDWriter


fn test_string_builder() raises:
    print("Testing new string builder performance")
    # Create a string from the buffer
    var new_builder_write_start_time = now()
    var new_builder = StringBuilder()
    for _ in range(10000):
        _ = new_builder.write_string(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod"
            " tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim"
            " veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea"
            " commodo consequat. Duis aute irure dolor in reprehenderit in voluptate"
            " velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint"
            " occaecat cupidatat non proident, sunt in culpa qui officia deserunt"
            " mollit anim id est laborum."
        )
    var new_builder_write_execution_time = now() - new_builder_write_start_time

    var new_builder_start_time = now()
    var new_output = str(new_builder)
    var new_builder_execution_time = now() - new_builder_start_time
    print("StringBuilder buffer len", len(new_output), "\n")

    var new_builder_render_start_time = now()
    var new_output_render = str(new_builder.render())
    var new_builder_render_execution_time = now() - new_builder_render_start_time
    print("StringBuilder buffer len", len(new_output_render), "\n")
    # print(new_output_render)

    # Create a string using the + operator
    print("Testing string concatenation performance")
    var vec = List[String]()
    for i in range(10000):
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
    print("Concat len", len(concat_output))

    print("\nWrite times:")
    print("StringBuilder:", "(", new_builder_write_execution_time, "ns)")

    print("\nExecution times:")
    print("StringBuilder:", "(", new_builder_execution_time, "ns)")
    print("StringBuilder Render:", "(", new_builder_render_execution_time, "ns)")
    print("String concat:", "(", concat_execution_time, "ns)")

    print("\nTotal Execution times:")
    print("StringBuilder:", "(", new_builder_execution_time + new_builder_write_execution_time, "ns)")
    print("String concat:", "(", concat_execution_time, "ns)")

    print(
        ": StringBuilder is ",
        str(concat_execution_time // (new_builder_execution_time + new_builder_write_execution_time)) + "x faster",
    )


# fn test_string_builder() raises:
#     print("Testing string builder performance")
#     # Create a string from the buffer
#     var builder_write_start_time = now()
#     var builder = LegacyStringBuilder()
#     for _ in range(10000):
#         _ = builder.write_string(
#             "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod"
#             " tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim"
#             " veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea"
#             " commodo consequat. Duis aute irure dolor in reprehenderit in voluptate"
#             " velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint"
#             " occaecat cupidatat non proident, sunt in culpa qui officia deserunt"
#             " mollit anim id est laborum."
#         )
#     var builder_write_execution_time = now() - builder_write_start_time

#     var builder_start_time = now()
#     var output = str(builder)
#     var builder_execution_time = now() - builder_start_time
#     print("LegacyStringBuilder buffer len", len(output), "\n")

#     print("Testing new string builder performance")
#     # Create a string from the buffer
#     var new_builder_write_start_time = now()
#     var new_builder = StringBuilder()
#     for _ in range(10000):
#         _ = new_builder.write_string(
#             "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod"
#             " tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim"
#             " veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea"
#             " commodo consequat. Duis aute irure dolor in reprehenderit in voluptate"
#             " velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint"
#             " occaecat cupidatat non proident, sunt in culpa qui officia deserunt"
#             " mollit anim id est laborum."
#         )
#     var new_builder_write_execution_time = now() - new_builder_write_start_time

#     var new_builder_start_time = now()
#     var new_output = str(new_builder)
#     var new_builder_execution_time = now() - new_builder_start_time
#     print("StringBuilder buffer len", len(new_output), "\n")

#     var new_builder_render_start_time = now()
#     var new_output_render = str(new_builder.render())
#     var new_builder_render_execution_time = now() - new_builder_render_start_time
#     print("StringBuilder buffer len", len(new_output_render), "\n")
#     # print(new_output_render)

#     # Create a string using the + operator
#     print("Testing string concatenation performance")
#     var vec = List[String]()
#     for i in range(10000):
#         vec.append(
#             "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod"
#             " tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim"
#             " veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea"
#             " commodo consequat. Duis aute irure dolor in reprehenderit in voluptate"
#             " velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint"
#             " occaecat cupidatat non proident, sunt in culpa qui officia deserunt"
#             " mollit anim id est laborum."
#         )

#     var concat_start_time = now()
#     var concat_output: String = ""
#     for i in range(len(vec)):
#         concat_output += vec[i]
#     var concat_execution_time = now() - concat_start_time
#     print("Concat len", len(concat_output), "\n")

#     # Create a string using a bytes buffer
#     var buffer_write_start_time = now()
#     print("Testing bytes buffer performance")
#     var buf = buffer.new_buffer()
#     for i in range(10000):
#         _ = buf.write_string(
#             "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod"
#             " tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim"
#             " veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea"
#             " commodo consequat. Duis aute irure dolor in reprehenderit in voluptate"
#             " velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint"
#             " occaecat cupidatat non proident, sunt in culpa qui officia deserunt"
#             " mollit anim id est laborum."
#         )
#     var buffer_write_execution_time = now() - buffer_write_start_time

#     var buffer_start_time = now()
#     var buffer_output = str(buf)
#     var buffer_execution_time = now() - buffer_start_time
#     print("Bytes buffer len", len(buffer_output))

#     print("\nWrite times:")
#     print("LegacyStringBuilder:", "(", builder_write_execution_time, "ns)")
#     print("StringBuilder:", "(", new_builder_write_execution_time, "ns)")
#     print("Bytes buffer write time:", "(", buffer_write_execution_time, "ns)")

#     print("\nExecution times:")
#     print("LegacyStringBuilder:", "(", builder_execution_time, "ns)")
#     print("StringBuilder:", "(", new_builder_execution_time, "ns)")
#     print("StringBuilder Render:", "(", new_builder_render_execution_time, "ns)")
#     print("String concat:", "(", concat_execution_time, "ns)")
#     print("Bytes Buffer:", "(", buffer_execution_time, "ns)")

#     print("\nTotal Execution times:")
#     print("LegacyStringBuilder:", "(", builder_execution_time + builder_write_execution_time, "ns)")
#     print("StringBuilder:", "(", new_builder_execution_time + new_builder_write_execution_time, "ns)")
#     print("String concat:", "(", concat_execution_time, "ns)")
#     print("Bytes Buffer:", "(", buffer_execution_time + buffer_write_execution_time, "ns)")

#     print(
#         ": LegacyStringBuilder is ",
#         str(concat_execution_time // (builder_execution_time + builder_write_execution_time)) + "x faster",
#         ": StringBuilder is ",
#         str(concat_execution_time // (new_builder_execution_time + new_builder_write_execution_time)) + "x faster",
#         ": Bytes Buffer is ",
#         str(concat_execution_time // (buffer_execution_time + buffer_write_execution_time)) + "x faster",
#     )


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

    # print("Testing new string builder performance")
    # # Create a string from the buffer
    # var new_builder_write_start_time = now()
    # var new_builder = StringBuilder()
    # for _ in range(100):
    #     _ = new_builder.write_string(
    #         "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod"
    #         " tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim"
    #         " veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea"
    #         " commodo consequat. Duis aute irure dolor in reprehenderit in voluptate"
    #         " velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint"
    #         " occaecat cupidatat non proident, sunt in culpa qui officia deserunt"
    #         " mollit anim id est laborum."
    #     )
    # var new_builder_write_execution_time = now() - new_builder_write_start_time
    # print("StringBuilder:", "(", new_builder_write_execution_time, "ns)")

    # var new_builder_start_time = now()
    # var new_output = str(new_builder)
    # var new_builder_execution_time = now() - new_builder_start_time
    # print(len(new_output))
    # # print(new_output)
    # print("StringBuilder:", "(", new_builder_execution_time, "ns)")
