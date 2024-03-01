from time import time_function, now
from io.writer import STDWriter


fn print_test() capturing:
    for i in range(1, 10000):
        print(i)


fn writer_test() raises:
    var start = now()
    var writer = STDWriter(1)
    for i in range(1, 10000):
        _ = writer.write_string(str(i))
    var end = now()
    print("\nwriter seconds: " + str((end - start) / 1e9))


fn main() raises:
    # print takes roughly 0.05 seconds
    # writer takes roughly 0.009 seconds. Roughly 5.5x faster
    print("print seconds:", time_function[print_test]() / 1e9)
    # print("writer time taken:", time_function[writer_wrapper]() / 10e8)
    writer_test()
