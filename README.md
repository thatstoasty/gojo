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

Please check out the `test`, `examples`, and `benchmarks` directories for usage of the various packages!

## Sharp Edges & Bugs

- Unicode characters are not supported until Mojo supports them. Sometimes it happens to work, but it's not guaranteed due to length discrepanices with ASCII and Unicode characters. If the character has a length of 2 or more, it probably will not work.
