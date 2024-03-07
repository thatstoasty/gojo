# gojo
Experiments in porting over Golang stdlib into Mojo.

## Usage
...

## What this includes
All of these packages are partially implemented.

- `bytes`
- `io`
  - Traits: `Reader`, `Writer`, `Seeker`, `Closer`, `ReadWriter`, `ReadCloser`, `WriteCloser`, `ReadWriteCloser`, `ReadSeeker`, `ReadSeekCloser`, `WriteSeeker`, `ReadWriteSeeker`, `ReaderFrom`, `WriterReadFrom`, `WriterTo`, `ReaderWriteTo`, `ReaderAt`, `WriterAt`, `ByteReader`, `ByteScanner`, `ByteWriter`, `StringWriter`
  - Reader and Writer wrapper functions.
  - `STDOUT/STDERR` Writer (leveraging `libc`).
  - `File` Reader/Writer (leveraging `libc`).
  - `FileHandle` Wrapper Reader/Writter (wraps around `FileHandle` to implement traits)
- `strings`
  - `StringBuilder`: String builder for fast string concatenation.
  - `Reader`: String reader.

WIP packages:
- `http`
- `fmt`