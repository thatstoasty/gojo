import benchmark
import gojo.bufio
import gojo.bytes
import gojo.strings
import testing


alias FIRE = "🔥"
alias NEWLINE = "\n"
alias CARRIAGE_RETURN = "\r"
alias SPACE = " "


fn benchmark_scan_runes[batches: Int]() -> None:
    var builder = strings.StringBuilder(capacity=batches * 4)
    for _ in range(batches):
        _ = builder.write_string(FIRE)

    var scanner = bufio.Scanner[bufio.scan_runes](bytes.Buffer(buf=str(builder).as_bytes()), capacity=batches)
    while scanner.scan():
        _ = scanner.current_token()


fn benchmark_scan_words[batches: Int]() -> None:
    var builder = strings.StringBuilder(capacity=batches * 5)
    for _ in range(batches):
        _ = builder.write_string(FIRE)
        _ = builder.write_string(SPACE)

    var scanner = bufio.Scanner[bufio.scan_words](bytes.Buffer(str(builder)), capacity=batches)
    while scanner.scan():
        _ = scanner.current_token()


fn benchmark_scan_lines[batches: Int]() -> None:
    var builder = strings.StringBuilder(capacity=batches * 5)
    for _ in range(batches):
        _ = builder.write_string(FIRE)
        _ = builder.write_string(NEWLINE)

    var scanner = bufio.Scanner(bytes.Buffer(str(builder)), capacity=batches)
    while scanner.scan():
        _ = scanner.current_token()


fn benchmark_scan_bytes[batches: Int]() -> None:
    var builder = strings.StringBuilder(capacity=batches)
    for _ in range(batches):
        _ = builder.write_string(SPACE)

    var scanner = bufio.Scanner[bufio.scan_bytes](bytes.Buffer(str(builder)), capacity=batches)
    while scanner.scan():
        _ = scanner.current_token()


fn benchmark_newline_split[batches: Int]() -> None:
    var builder = strings.StringBuilder(capacity=batches * 5)
    for _ in range(batches):
        _ = builder.write_string(FIRE)
        _ = builder.write_string(NEWLINE)

    try:
        var lines = str(builder).split(NEWLINE)
        for line in lines:
            _ = line
    except e:
        pass


fn main():
    # There's a time penalty for building the input text, for now.
    print("Running benchmark_scan_runes - 100")
    var report = benchmark.run[benchmark_scan_runes[100]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_scan_runes - 1000")
    report = benchmark.run[benchmark_scan_runes[1000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_scan_runes - 10000")
    report = benchmark.run[benchmark_scan_runes[10000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_scan_words - 100")
    report = benchmark.run[benchmark_scan_words[100]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_scan_words - 1000")
    report = benchmark.run[benchmark_scan_words[1000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_scan_words - 10000")
    report = benchmark.run[benchmark_scan_words[10000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_scan_lines - 100")
    report = benchmark.run[benchmark_scan_lines[100]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_scan_lines - 1000")
    report = benchmark.run[benchmark_scan_lines[1000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_scan_lines - 10000")
    report = benchmark.run[benchmark_scan_lines[10000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    # To compare against scan lines
    print("Running benchmark_newline_split - 10000")
    report = benchmark.run[benchmark_newline_split[10000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_scan_bytes - 100")
    report = benchmark.run[benchmark_scan_bytes[100]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_scan_bytes - 1000")
    report = benchmark.run[benchmark_scan_bytes[1000]](max_iters=20)
    report.print(benchmark.Unit.ms)

    print("Running benchmark_scan_bytes - 10000")
    report = benchmark.run[benchmark_scan_bytes[10000]](max_iters=20)
    report.print(benchmark.Unit.ms)
