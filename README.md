# gojo

Experiments in porting over Golang stdlib into Mojo. This is not intended to be a full port, but rather a learning exercise and a way to experiment with Mojo's capabilities. Please feel free to contribute or use this as a starting point for your own projects! The codebase will remain in flux and will evolve with Mojo as future releases are created.

## Projects that use Gojo

### My projects

- `weave`: A collection of (ANSI-sequence aware) text reflow operations &amp; algorithms. [Link to the project.](https://github.com/thatstoasty/weave)
- `mog`: Terminal text styling library. [Link to the project.](https://github.com/thatstoasty/mog)

## What this includes

All of these packages are partially implemented.

- `builtins`
  - `Bytes` struct (backed by DynamicVector[Int8])
- `bufio`
  - `Reader`: Buffered `io.Reader`
  - `Scanner`: Scanner interface to read data via tokens.
- `bytes`
  - `Buffer`: Buffer backed by `Bytes` struct.
  - `Reader`: Reader backed by `Bytes` struct.
- `io`
  - Traits: `Reader`, `Writer`, `Seeker`, `Closer`, `ReadWriter`, `ReadCloser`, `WriteCloser`, `ReadWriteCloser`, `ReadSeeker`, `ReadSeekCloser`, `WriteSeeker`, `ReadWriteSeeker`, `ReaderFrom`, `WriterReadFrom`, `WriterTo`, `ReaderWriteTo`, `ReaderAt`, `WriterAt`, `ByteReader`, `ByteScanner`, `ByteWriter`, `StringWriter`
  - `Reader` and `Writer` wrapper functions.
  - `STDOUT/STDERR` Writer (leveraging `libc`).
  - `FileWrapper`: `FileHandle` Wrapper Reader/Writer
- `strings`
  - `StringBuilder`: String builder for fast string concatenation.
  - `Reader`: String reader.
- `fmt`
  - Basic `sprintf` function.

## Usage

Some basic usage examples. For now, check out the tests for usage of the various packages!

`builtins.Bytes`

```py
from tests.wrapper import MojoTest
from gojo.builtins._bytes import Bytes


fn test_bytes() raises:
    var test = MojoTest("Testing bytes")
    var bytes = Bytes(s="hello")
    test.assert_equal(str(bytes), "hello")

    bytes.append(102)
    test.assert_equal(str(bytes), "hellof")

    bytes += String(" World").as_bytes()
    test.assert_equal(str(bytes), "hellof World")

    var bytes2 = DynamicVector[Int8]()
    bytes2.append(104)
    bytes.extend(bytes2)
    test.assert_equal(str(bytes), "hellof Worldh")
```

`bufio.Scanner`

```py
from tests.wrapper import MojoTest
from gojo.bytes import buffer
from gojo.builtins._bytes import Bytes
from gojo.bufio import Reader, Scanner, scan_words, scan_bytes
from gojo.io import FileWrapper

fn test_scan_words() raises:
    var test = MojoTest("Testing scan_words")

    # Create a reader from a string buffer
    var s: String = "Testing this string!"
    var buf = buffer.new_buffer(s)
    var r = Reader(buf)

    # Create a scanner from the reader
    var scanner = Scanner(r ^)
    scanner.split = scan_words

    var expected_results = DynamicVector[String]()
    expected_results.append("Testing")
    expected_results.append("this")
    expected_results.append("string!")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.current_token(), expected_results[i])
        i += 1


fn test_scan_lines() raises:
    var test = MojoTest("Testing scan_lines")

    # Create a reader from a string buffer
    var s: String = "Testing\nthis\nstring!"
    var buf = buffer.new_buffer(s)
    var r = Reader(buf)

    # Create a scanner from the reader
    var scanner = Scanner(r ^)

    var expected_results = DynamicVector[String]()
    expected_results.append("Testing")
    expected_results.append("this")
    expected_results.append("string!")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.current_token(), expected_results[i])
        i += 1


fn test_scan_bytes() raises:
    var test = MojoTest("Testing scan_bytes")

    # Create a reader from a string buffer
    var s: String = "abc"
    var buf = buffer.new_buffer(s)
    var r = Reader(buf)

    # Create a scanner from the reader
    var scanner = Scanner(r ^)
    scanner.split = scan_bytes

    var expected_results = DynamicVector[String]()
    expected_results.append("a")
    expected_results.append("b")
    expected_results.append("c")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.current_token_as_bytes(), Bytes(expected_results[i]))
        i += 1


fn test_file_wrapper_scanner() raises:
    var test = MojoTest("testing io.FileWrapper and bufio.Scanner")
    var file = FileWrapper("test_multiple_lines.txt", "r")

    # Create a scanner from the reader
    var scanner = Scanner(file ^)
    var expected_results = DynamicVector[String]()
    expected_results.append("11111")
    expected_results.append("22222")
    expected_results.append("33333")
    expected_results.append("44444")
    expected_results.append("55555")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.current_token(), expected_results[i])
        i += 1
```

`bufio.Reader`

```py
from tests.wrapper import MojoTest
from gojo.bytes import buffer
from gojo.builtins._bytes import Bytes
from gojo.bufio import Reader, Scanner, scan_words, scan_bytes
from gojo.io import FileWrapper


fn test_reader() raises:
    var test = MojoTest("Testing reader")

    # Create a reader from a string buffer
    var s: String = "Hello"
    var buf = buffer.new_buffer(s)
    var r = Reader(buf)

    # Read the buffer into Bytes and then add more to Bytes
    var dest = Bytes(256)
    _ = r.read(dest)
    dest.extend(" World!")

    test.assert_equal(dest, "Hello World!")
```

`bytes.Buffer`

```py
from tests.wrapper import MojoTest
from gojo.builtins._bytes import Bytes
from gojo.bytes.buffer import new_buffer, Buffer


fn test_read() raises:
    var test = MojoTest("Testing read")
    var s: String = "Hello World!"
    var buf = new_buffer(s)
    var dest = Bytes(256)
    _ = buf.read(dest)
    test.assert_equal(str(dest), s)


fn test_write() raises:
    var test = MojoTest("Testing write")
    var b = Bytes(256)
    var buf = new_buffer(b ^)
    _ = buf.write(Bytes("Hello World!"))
    test.assert_equal(str(buf), String("Hello World!"))

    print("Testing write_string")
    _ = buf.write_string("\nGoodbye World!")
    test.assert_equal(str(buf), String("Hello World!\nGoodbye World!"))

    print("Testing write_byte")
    _ = buf.write_byte(0x41)
    test.assert_equal(str(buf), String("Hello World!\nGoodbye World!A"))
```

`bytes.Reader`

```py
from tests.wrapper import MojoTest
from gojo.builtins._bytes import Bytes
from gojo.bytes.buffer import new_buffer, new_buffer, Buffer


fn test_reader() raises:
    var test = MojoTest("Testing bytes.Reader")

    # Create a new reader from string s. It is converted to Bytes upon init.
    var s: String = "Hello World!"
    var buf = new_reader(s)

    # Read the contents of reader into dest
    var dest = Bytes()
    _ = buf.read(dest)
    test.assert_equal(str(dest), s)
```

`io.FileWrapper`

```py
from tests.wrapper import MojoTest
from gojo.io.file import File, FileWrapper
from gojo.io.reader import Reader
from gojo.io.std_writer import STDWriter
from gojo.external.libc import FD_STDOUT, FD_STDIN, FD_STDERR
from gojo.builtins._bytes import Bytes


fn test_file_wrapper() raises:
    var test = MojoTest("Testing io.FileWrapper")
    var file = FileWrapper("test.txt", "r")
    var dest = Bytes(1200)
    _ = file.read(dest)
    test.assert_equal(String(dest), String(Bytes("12345")))
```

`io.STDWriter`

```py
from tests.wrapper import MojoTest
from gojo.io.file import File, FileWrapper
from gojo.io.reader import Reader
from gojo.io.std_writer import STDWriter
from gojo.external.libc import FD_STDOUT, FD_STDIN, FD_STDERR
from gojo.builtins._bytes import Bytes

fn test_writer() raises:
    var test = MojoTest("Testing io.STDWriter")
    var writer = STDWriter(int(FD_STDOUT))
    _ = writer.write_string("")
```

`fmt.sprintf`

```py
from tests.wrapper import MojoTest
from gojo.fmt import sprintf


fn test_sprintf() raises:
    var test = MojoTest("Testing sprintf")
    var s = sprintf(
        (
            "Hello, %s. I am %d years old. More precisely, I am %f years old. It is %t"
            " that I like Mojo!"
        ),
        String("world"),
        29,
        Float64(29.5),
        True,
    )
    test.assert_equal(
        s,
        (
            "Hello, world. I am 29 years old. More precisely, I am 29.5 years old. It"
            " is True that I like Mojo!"
        ),
    )
```

`strings.Reader`

```py
from tests.wrapper import MojoTest
from gojo.strings import StringBuilder, Reader, new_reader
from gojo.builtins import Bytes
import gojo.io

fn test_string_reader() raises:
    var test = MojoTest("Testing strings.Reader")
    var example: String = "Hello, World!"
    var reader = new_reader("Hello, World!")

    # Test reading from the reader.
    var buffer = Bytes()
    var bytes_read = reader.read(buffer)

    test.assert_equal(bytes_read, len(example))
    test.assert_equal(str(buffer), "Hello, World!")

    # Seek to the beginning of the reader.
    var position = reader.seek(0, io.SEEK_START)
    test.assert_equal(position, 0)

    # Read the first byte from the reader.
    buffer = Bytes()
    var byte = reader.read_byte()
    test.assert_equal(byte, 72)

    # Unread the first byte from the reader. Remaining bytes to be read should be the same as the length of the example string.
    reader.unread_byte()
    test.assert_equal(len(reader), len(example))

    # Write from the string reader to a StringBuilder.
    var builder = StringBuilder()
    _ = reader.write_to(builder)
    test.assert_equal(str(builder), example)
```

`strings.StringBuilder`

```py
from tests.wrapper import MojoTest
from gojo.strings import StringBuilder, Reader, new_reader
from gojo.builtins import Bytes
import gojo.io

fn test_string_builder() raises:
    var test = MojoTest("Testing strings.StringBuilder")

    # Create a string from the builder by writing strings to it.
    var builder = StringBuilder()

    for i in range(3):
        _ = builder.write_string("Lorem ipsum dolor sit amet ")

    test.assert_equal(
        str(builder),
        (
            "Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor"
            " sit amet "
        ),
    )

    # Create a string from the builder by writing bytes to it.
    builder = StringBuilder()
    _ = builder.write(Bytes("Hello"))
    _ = builder.write_byte(32)
    test.assert_equal(str(builder), "Hello ")
```

## Sharp Edges & Bugs

- TODO: `bufio.Reader.read_line` is broken until Mojo support unpacking Memory only types from return Tuples.
