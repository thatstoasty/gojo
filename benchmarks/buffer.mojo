import gojo.bytes
import benchmark
import time
import pathlib

alias SAMPLE_TEXT = """Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."""


fn benchmark_bytes_buffer[batches: Int]():
    var buffer = bytes.Buffer(capacity=batches * len(SAMPLE_TEXT))
    for _ in range(batches):
        _ = buffer.write_string(SAMPLE_TEXT)
    _ = str(buffer)


fn benchmark_consume_and_str() raises:
    var buffer = bytes.Buffer()
    var path = str(pathlib._dir_of_current_file()) + "/data/test_big_file.txt"
    with open(path, "r") as file:
        var data = file.read()
        for _ in range(10):
            _ = buffer.write_string(data)

        var start = time.perf_counter_ns()
        var result = str(buffer)
        print("Stringify buffer: ", time.perf_counter_ns() - start)

        start = time.perf_counter_ns()
        result = buffer.consume()
        print("Consume buffer: ", time.perf_counter_ns() - start)
        _ = result


fn main() raises:
    print("Running benchmark_bytes_buffer - 100 batches")
    report = benchmark.run[benchmark_bytes_buffer[100]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_bytes_buffer - 1000 batches")
    report = benchmark.run[benchmark_bytes_buffer[1000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_bytes_buffer - 10000 batches")
    report = benchmark.run[benchmark_bytes_buffer[10000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_consume_and_str")
    benchmark_consume_and_str()
