trait Writer(Movable):
    fn write(inout self, src: Span[UInt8]) -> (Int, Error):
        ...


@value
struct TestWriter(Writer):
    fn write(inout self, src: Span[UInt8]) -> (Int, Error):
        return len(src), Error()


fn do_write[W: Writer](inout writer: W, src: Span[UInt8]) -> (Int, Error):
    return writer.write(src)


fn main():
    var writer = TestWriter()
    var data = List[UInt8](10)
    _ = writer.write(Span(data))
    _ = do_write(writer, Span(data))
