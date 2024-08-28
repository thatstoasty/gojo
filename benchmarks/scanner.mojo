import benchmark
import gojo.bufio
import gojo.bytes
import gojo.strings
import testing


alias FIRE = "🔥"


fn benchmark_scan_runes[batches: Int]() -> None:
    var builder = strings.StringBuilder(capacity=batches)
    for _ in range(batches):
        _ = builder.write_string(FIRE)

    var buf = bytes.Buffer(buf=str(builder).as_bytes())
    var scanner = bufio.Scanner[split = bufio.scan_runes, capacity=batches](buf^)
    while scanner.scan():
        _ = scanner.current_token()


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
