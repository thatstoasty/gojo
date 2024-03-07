# gojo
Experiments in porting over Golang stdlib into Mojo. This is not intended to be a full port, but rather a learning exercise and a way to experiment with Mojo's capabilities. Please feel free to contribute or use this as a starting point for your own projects! The codebase will remain in flux and will evolve with Mojo as future releases are created.

## Usage
...

## What this includes
All of these packages are partially implemented.

- `builtins`
  - `Bytes` struct (backed by DynamicVector[Int8])
- `bytes`
  - `Buffer` backed by `Bytes` struct for internal storage.
- `io`
  - Traits: `Reader`, `Writer`, `Seeker`, `Closer`, `ReadWriter`, `ReadCloser`, `WriteCloser`, `ReadWriteCloser`, `ReadSeeker`, `ReadSeekCloser`, `WriteSeeker`, `ReadWriteSeeker`, `ReaderFrom`, `WriterReadFrom`, `WriterTo`, `ReaderWriteTo`, `ReaderAt`, `WriterAt`, `ByteReader`, `ByteScanner`, `ByteWriter`, `StringWriter`
  - `Reader` and `Writer` wrapper functions.
  - `STDOUT/STDERR` Writer (leveraging `libc`).
  - `File` Reader/Writer (leveraging `libc`).
  - `FileHandle` Wrapper Reader/Writer
- `strings`
  - `StringBuilder`: String builder for fast string concatenation.
  - `Reader`: String reader.

WIP packages:

- `http`
- `fmt`
