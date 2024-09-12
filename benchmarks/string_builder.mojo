import benchmark
from gojo.strings import StringBuilder
from gojo.bytes.buffer import Buffer

alias SAMPLE_TEXT = """Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."""


fn benchmark_concat[batches: Int]():
    var vec = List[String](capacity=batches * len(SAMPLE_TEXT))
    for _ in range(batches):
        vec.append(SAMPLE_TEXT)

    var concat_output: String = ""
    for i in range(len(vec)):
        concat_output += vec[i]
    _ = concat_output


fn benchmark_string_builder[batches: Int]():
    var new_builder = StringBuilder(capacity=batches * len(SAMPLE_TEXT))
    for _ in range(batches):
        _ = new_builder.write_string(SAMPLE_TEXT)
    _ = str(new_builder)


fn benchmark_bytes_buffer[batches: Int]():
    var buffer = Buffer(capacity=batches * len(SAMPLE_TEXT))
    for _ in range(batches):
        _ = buffer.write_string(SAMPLE_TEXT)
    _ = str(buffer)


fn main():
    # There's a performance penalty for benchmark concat bc it also includes
    # the building of the list of strings it concatenates. Trying to build it at comptime takes a loooong time.
    print("Running benchmark_concat - 100 batches")
    var report = benchmark.run[benchmark_concat[100]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_string_builder - 100 batches")
    report = benchmark.run[benchmark_string_builder[100]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_bytes_buffer - 100 batches")
    report = benchmark.run[benchmark_bytes_buffer[100]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_concat - 1000 batches")
    report = benchmark.run[benchmark_concat[1000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_string_builder - 1000 batches")
    report = benchmark.run[benchmark_string_builder[1000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_bytes_buffer - 1000 batches")
    report = benchmark.run[benchmark_bytes_buffer[1000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_concat - 10000 batches")
    report = benchmark.run[benchmark_concat[10000]](max_iters=2)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_string_builder - 10000 batches")
    report = benchmark.run[benchmark_string_builder[10000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_bytes_buffer - 10000 batches")
    report = benchmark.run[benchmark_bytes_buffer[10000]](max_iters=20)
    report.print(benchmark.Unit.ms)
