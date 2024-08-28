import benchmark
import gojo.bufio
import gojo.bytes
import testing


fn benchmark_scan_runes() -> None:
    var input = String("Hello, World!").as_bytes()
    var buf = bytes.Buffer(buf=input^)
    var scanner = bufio.Scanner[split = bufio.scan_runes](buf^)

    while scanner.scan():
        print(scanner.current_token())


fn main():
    print("Running benchmark_scan_runes")
    var report = benchmark.run[benchmark_scan_runes](max_iters=20)
    report.print(benchmark.Unit.ms)
