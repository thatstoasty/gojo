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
    
    # TODO: This is slicing off the very last character of the file
    fn read_lines(inout self, lines_to_read: Int, delimiter: String, column_count: Int = 1) raises -> CsvTable:
        var lines_remaining = lines_to_read
        var builder = CsvBuilder(column_count)
        while lines_remaining != 0:
            var result = self.reader.read_string(ord(delimiter))
            if result.has_error():
                if str(result.unwrap_error()) != io.EOF:
                    raise result.unwrap_error().error
            
            # read_string includes the delimiter in the result, so we slice off whatever the length of the delimiter is from the end
            var fields = result.value[:(-1 * len(delimiter))].split(",")
            for field in fields:
                builder.push(field[])
            lines_remaining -= 1

        return CsvTable(builder^.finish())


struct CSVWriter[W: io.Writer]():
    var writer: bufio.Writer[W]

    fn __init__(inout self, owned writer: W) raises:
        self.writer = bufio.Writer(writer ^)

    fn __moveinit__(inout self, owned existing: Self):
        self.writer = existing.writer ^
    
    fn write(inout self, src: CsvTable) raises -> Int:
        var result = self.writer.write_string(src._inner_string)
        if result.has_error():
            var error = result.unwrap_error()
            if str(error) != io.EOF:
                raise error.error
        
        # Flush remaining contents of buffer
        var error = self.writer.flush()
        if error:
            var err = error.value().error
            if str(err) != io.EOF:
                raise err
                
        return result.value
    
    fn write(inout self, src: DynamicVector[String]) raises -> Int:
        var bytes_written: Int = 0
        for row in src:
            var result = self.writer.write_string(row[] + "\r\n")
            if result.has_error():
                var error = result.unwrap_error()
                if str(error) != io.EOF:
                    raise error.error
            
            bytes_written += result.value
        
        # Flush remaining contents of buffer
        var error = self.writer.flush()
        if error:
            var err = error.value().error
            if str(err) != io.EOF:
                raise err
        
        return bytes_written
    