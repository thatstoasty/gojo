# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

## [0.1.9] - 2024-09-13

- Fix usage of abort instead of panic.

## [0.1.8] - 2024-09-13

- Lot's of changes since Mojo 24.5. Sorry, I don't have a more granualar changelog!

## [0.0.2] - 2024-06-19

### Added

- UDP support in `net` package.
- `examples` package with `tcp` and `udp` examples using `Socket` and their respective `dial` and `listen` functions.
- Added `scan_runes` split function to `bufio.scan` module.
- Added `bufio.Scanner` examples to the `examples` directory.

### Removed

- `Listener`, `Dialer`, and `Conn` interfaces have been removed until Trait support improves. For now, call `listen_tcp/listen_udp` and `dial_tcp/dial_udp` functions directly.

### Changed

- Incrementally moving towards using `Span` for the `Reader` and `Writer` traits. Added an `_read` function to `Reader` and `_read_at` to `ReaderAt` traits to enable reading into `Span`. The usual implementation is the take a `List[UInt8]` but then to use `_read` and pass a `Span` constructed from the List.

## [0.0.1] - 2024-06-16

### Changed

- Moved benchmarks to their own folder.
- Switch to more general usage of `Span[UInt8]` instead of copying bytes where possible.
- `bufio` `Reader` and `Writer` now use `InlineList` for the backing buffer because it does not need to grow.
- `bufio` `Scanner` now uses `UnsafePointer[UInt8]` for the backing buffer, which is more unsafe than `List[UInt8]` but faster.
- `bytes` `Buffer` and `Reader` now use `UnsafePointer[UInt8]` for the backing buffer, which is more unsafe than `List[UInt8]` but faster.
- `goodies` package has been retired and folded into the `gojo.io` module.
- `strings` `StringBuilder` now uses `UnsafePointer[UInt8]` instead of a `DTypePointer[DType.uint8]` for better compability with `List`.
