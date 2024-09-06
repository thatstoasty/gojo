# gojo

Experiments in porting over Golang stdlib into Mojo and extra goodies that make use of it. It will not always be a 1:1 port, it's more so code inspired by the Golang stdlib and the Mojo community's code. This is not intended to be a full port, but rather a learning exercise and a way to experiment with Mojo's capabilities. Please feel free to contribute or use this as a starting point for your own projects! The codebase will remain in flux and will evolve with Mojo as future releases are created.

## Installation

1. First, you'll need to configure your `mojoproject.toml` file to include my Conda channel. Add `"https://repo.prefix.dev/mojo-community"` to the list of channels.
2. Next, add `gojo` to your project's dependencies by running `magic add gojo`.
3. Finally, run `magic install` to install in `gojo`. You should see the `.mojopkg` files in `$CONDA_PREFIX/lib/mojo/`.

## Projects that use Gojo

### My projects

- `weave`: A collection of (ANSI-sequence aware) text reflow operations &amp; algorithms. [Link to the project.](https://github.com/thatstoasty/weave)
- `mog`: Terminal text styling library. [Link to the project.](https://github.com/thatstoasty/mog)
- `stump`: Bound Logger library. [Link to the project.](https://github.com/thatstoasty/stump)
- `prism`: CLI Library. [Link to the project.](https://github.com/thatstoasty/prism)

### Community projects

- `lightbug_http`: Simple and fast HTTP framework for Mojo! 🔥 [Link to the project.](https://github.com/saviorand/lightbug_http/tree/main)

## What this includes

All of these packages are partially implemented and do not support unicode characters until Mojo supports them.

### Gojo

- `bufio`
  - `Reader`: Buffered `io.Reader`
  - `Scanner`: Scanner interface to read data via tokens.
- `bytes`
  - `Buffer`: Buffer backed by `UnsafePointer[UInt8]`.
  - `Reader`: Reader backed by `UnsafePointer[UInt8]`.
- `io`
  - Traits: `Reader`, `Writer`, `Seeker`, `Closer`, `ReadWriter`, `ReadCloser`, `WriteCloser`, `ReadWriteCloser`, `ReadSeeker`, `ReadSeekCloser`, `WriteSeeker`, `ReadWriteSeeker`, `ReaderFrom`, `WriterReadFrom`, `WriterTo`, `ReaderWriteTo`, `ReaderAt`, `WriterAt`, `ByteReader`, `ByteScanner`, `ByteWriter`, `StringWriter`
  - `Reader` and `Writer` wrapper functions.
  - `FileWrapper`: `FileHandle` Wrapper Reader/Writer
  - `STDOUT/STDERR` Writer (leveraging `libc`).
- `strings`
  - `StringBuilder`: String builder for fast string concatenation.
  - `Reader`: String reader.
- `fmt`
  - Basic `sprintf` function.
- `syscall`
  - External call wrappers for `libc` functions and types.
- `net`
  - `Socket`: Wraps `FileDescriptor` and implements network specific functions.
  - `FileDescriptor`: File Descriptor wrapper that implements `io.Writer`, `io.Reader`, and `io.Closer`.
  - `Dial` and `Listen` functions. (for TCP and UDP only atm).

## Usage

Some basic usage examples. These examples may fall out of sync, so please check out the tests for usage of the various packages!

You can copy over the modules you want to use from the `gojo` or `goodies` directories, or you can build the package by running:
For `gojo`: `mojo package gojo -I .`

`bufio.Scanner`

```mojo
from tests.wrapper import MojoTest
from gojo.bytes import buffer
from gojo.io import FileWrapper
from gojo.bufio import Reader, Scanner, scan_words, scan_bytes


fn test_scan_words() raises:
    var test = MojoTest("Testing scan_words")

    # Create a reader from a string buffer
    var s: String = "Testing this string!"
    var buf = buffer.new_buffer(s)
    var r = Reader(buf^)

    # Create a scanner from the reader
    var scanner = Scanner(r^)
    scanner.split = scan_words

    var expected_results = List[String]()
    expected_results.append("Testing")
    expected_results.append("this")
    expected_results.append("string!")
    var i = 0

    while scanner.scan():
        test.assert_equal(scanner.current_token(), expected_results[i])
        i += 1
```

`bufio.Reader`

```mojo
from tests.wrapper import MojoTest
from gojo.bytes import buffer
from gojo.builtins.bytes import to_string
from gojo.bufio import Reader, Scanner, scan_words, scan_bytes, Writer
from gojo.io import read_all, FileWrapper
from gojo.strings import StringBuilder


fn test_read():
    var test = MojoTest("Testing bufio.Reader.read")

    # Create a reader from a string buffer
    var s: String = "Hello"
    var buf = buffer.new_buffer(s)
    var reader = Reader(buf^)

    # Read the buffer into List[UInt8] and then add more to List[UInt8]
    var dest = List[UInt8](capacity=256)
    _ = reader.read(dest)
    dest.extend(String(" World!").as_bytes())

    test.assert_equal(to_string(dest), "Hello World!")
```

`bytes.Buffer`

```mojo
from tests.wrapper import MojoTest
from gojo.bytes import new_buffer
from gojo.bytes.buffer import Buffer


fn test_read() raises:
    var test = MojoTest("Testing bytes.Buffer.read")
    var s: String = "Hello World!"
    var buf = new_buffer(s)
    var dest = List[UInt8](capacity=16)
    _ = buf.read(dest)
    dest.append(0)
    test.assert_equal(String(dest), s)


fn test_write() raises:
    var test = MojoTest("Testing bytes.Buffer.write")
    var b = List[UInt8](capacity=16)
    var buf = new_buffer(b^)
    _ = buf.write(String("Hello World!").as_bytes_slice())
    test.assert_equal(str(buf), String("Hello World!"))
```

`bytes.Reader`

```mojo
from tests.wrapper import MojoTest
from gojo.bytes import reader, buffer
import gojo.io


fn test_read() raises:
    var test = MojoTest("Testing bytes.Reader.read")
    var reader = reader.new_reader("0123456789")
    var dest = List[UInt8](capacity=16)
    _ = reader.read(dest)
    dest.append(0)
    test.assert_equal(String(dest), "0123456789")

    # Test negative seek
    alias NEGATIVE_POSITION_ERROR = "bytes.Reader.seek: negative position"
    var position: Int
    var err: Error
    position, err = reader.seek(-1, io.SEEK_START)

    if not err:
        raise Error("Expected error not raised while testing negative seek.")

    if str(err) != NEGATIVE_POSITION_ERROR:
        raise err

    test.assert_equal(str(err), NEGATIVE_POSITION_ERROR)
```

`io.FileWrapper`

```mojo
from tests.wrapper import MojoTest
from gojo.io import read_all, FileWrapper


fn test_read() raises:
    var test = MojoTest("Testing FileWrapper.read")
    var file = FileWrapper("tests/data/test.txt", "r")
    var dest = List[UInt8](capacity=16)
    _ = file.read(dest)
    dest.append(0)
    test.assert_equal(String(dest), "12345")
```

`io.STDWriter`

```mojo
from tests.wrapper import MojoTest
from gojo.syscall import FD
from gojo.io import STDWriter


fn test_writer() raises:
    var test = MojoTest("Testing STDWriter.write")
    var writer = STDWriter[FD.STDOUT]()
    _ = writer.write_string("")
```

`fmt.sprintf`

```mojo
from tests.wrapper import MojoTest
from gojo.fmt import sprintf, printf


fn test_sprintf() raises:
    var test = MojoTest("Testing sprintf")
    var s = sprintf(
        "Hello, %s. I am %d years old. More precisely, I am %f years old. It is %t that I like Mojo!",
        String("world"),
        29,
        Float64(29.5),
        True,
    )
    test.assert_equal(
        s,
        "Hello, world. I am 29 years old. More precisely, I am 29.5 years old. It is True that I like Mojo!",
    )

    s = sprintf("This is a number: %d. In base 16: %x. In base 16 upper: %X.", 42, 42, 42)
    test.assert_equal(s, "This is a number: 42. In base 16: 2a. In base 16 upper: 2A.")

    s = sprintf("Hello %s", String("world").as_bytes())
    test.assert_equal(s, "Hello world")
```

`strings.Reader`

```mojo
from tests.wrapper import MojoTest
from gojo.strings import StringBuilder, Reader, new_reader
import gojo.io


fn test_read() raises:
    var test = MojoTest("Testing strings.Reader.read")
    var example: String = "Hello, World!"
    var reader = new_reader("Hello, World!")

    # Test reading from the reader.
    var buffer = List[UInt8](capacity=16)
    var bytes_read = reader.read(buffer)
    buffer.append(0)

    test.assert_equal(bytes_read[0], len(example))
    test.assert_equal(String(buffer), "Hello, World!")
```

`strings.StringBuilder`

```mojo
from tests.wrapper import MojoTest
from gojo.strings import StringBuilder

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

```

## Sharp Edges & Bugs

- Unicode characters are not supported until Mojo supports them. Sometimes it happens to work, but it's not guaranteed due to length discrepanices with ASCII and Unicode characters. If the character has a length of 2 or more, it probably will not work.
