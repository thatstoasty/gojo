
# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - yyyy-mm-dd

## [0.0.1] - 2024-06-16

### Changed

- Moved benchmarks to their own folder.
- Switch to more general usage of `Span[UInt8]` instead of copying bytes where possible.
- `bufio` `Reader` and `Writer` now use `InlineList` for the backing buffer because it does not need to grow.
- `bufio` `Scanner` now uses `UnsafePointer[UInt8]` for the backing buffer, which is more unsafe than `List[UInt8]` but faster.
- `bytes` `Buffer` and `Reader` now use `UnsafePointer[UInt8]` for the backing buffer, which is more unsafe than `List[UInt8]` but faster.
- `goodies` package has been retired and folded into the `gojo.io` module.
- `strings` `StringBuilder` now uses `UnsafePointer[UInt8]` instead of a `DTypePointer[DType.uint8]` for better compability with `List`.
