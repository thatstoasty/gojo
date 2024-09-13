# fn test_std_writer_speed() raises:
#     """STDWriter is roughly 6-7x faster currently."""
#     var print_start_time = now()
#     for i in range(1, 10000):
#         print(i)
#     var print_execution_time = now() - print_start_time

#     # Create stdout writer
#     var writer = STDWriter(1)
#     var writer_start_time = now()
#     for i in range(1, 10000):
#         _ = writer.write_string(str(i))
#     var writer_execution_time = now() - writer_start_time

#     print("\n\nprint execution time (s): " + str((print_execution_time) / 1e9))
#     print("writer execution time (s): " + str((writer_execution_time) / 1e9))
#     print("Writer is ", str(print_execution_time // writer_execution_time) + "x faster")
