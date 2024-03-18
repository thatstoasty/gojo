from gojo.builtins import Bytes
import gojo.io
import gojo.bufio
from gojo.strings import StringBuilder
from external.csv import CsvBuilder, CsvTable
from .file import FileWrapper


struct CSVReader[R: io.Reader]():
    var reader: bufio.Reader[R]

    fn __init__(inout self, owned reader: R) raises:
        self.reader = bufio.Reader(reader ^)

    fn __moveinit__(inout self, owned existing: Self):
        self.reader = existing.reader ^
    
    fn read_lines(inout self, lines_to_read: Int, delimiter: String, column_count: Int = 1) raises -> CsvTable:
        var lines_remaining = lines_to_read
        var builder = CsvBuilder(column_count)
        while lines_remaining != 0:
            var result = self.reader.read_string(ord(delimiter))
            if result.has_error():
                if str(result.unwrap_error()) != io.EOF:
                    raise result.unwrap_error().error
            
            # read_string includes the delimiter in the result, so we slice off whatever the length of the delimiter is from the end
            builder.push(result.value[:(-1 * len(delimiter))])
            lines_remaining -= 1

        return CsvTable(builder^.finish())


struct CSVWriter():
    var file: FileWrapper
    var buffer: Bytes

    fn __init__(inout self, path: String, mode: String) raises:
        self.file = FileWrapper(path, mode)
        self.buffer = Bytes(4096)

    fn __moveinit__(inout self, owned existing: Self):
        self.file = existing.file ^
        self.buffer = existing.buffer ^
    
    fn write(inout self, src: Bytes) raises -> Int:
        if src.size() + self.buffer.available() > len(self.buffer):
            self.flush()

        self.buffer.extend(src)
        return src.size()
    
    fn flush(inout self) raises:
        if self.buffer.size() > 0:
            var builder = CsvBuilder(1)
            builder.push(self.buffer)
            _ = self.file.write(builder^.finish())
