from gojo.io import FileWrapper
from gojo.builtins import Bytes
from external.csv import CsvBuilder, CsvTable


struct CSVReader():
    var file: FileWrapper
    var buffer: Bytes

    fn __init__(inout self, path: String, mode: StringLiteral) raises:
        self.file = FileWrapper(path, mode)
        self.buffer = Bytes(4096)

    fn __moveinit__(inout self, owned existing: Self):
        self.file = existing.file ^
        self.buffer = existing.buffer
    
    fn read(inout self, column_count: Int = 1) raises -> CsvTable:
        self.buffer = self.file.read_all()
        var builder = CsvBuilder(column_count)
        builder.push(self.buffer)

        return CsvTable(builder^.finish())


struct CSVWriter():
    var file: FileWrapper
    var buffer: Bytes

    fn __init__(inout self, path: String, mode: StringLiteral) raises:
        self.file = FileWrapper(path, mode)
        self.buffer = Bytes(4096)

    fn __moveinit__(inout self, owned existing: Self):
        self.file = existing.file ^
        self.buffer = existing.buffer
    
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


fn write_csv() raises:
    var file = FileWrapper("test.csv", "w")
    var csv = CsvBuilder(3)
    csv.push("Hello")
    csv.push("World")
    csv.push("I am here", True)

    var csv_text = csv^.finish()
    _ = file.write(csv_text)


fn read_csv() raises:
    with open("test.csv", "r") as file:
        var builder = CsvBuilder(3)
        builder.push(file.read())
        var csv_text = builder^.finish()
        var csv = CsvTable(csv_text)
        var data = csv.get(0, 0)
        print(data)


fn csv_reader() raises:
    var reader = CSVReader("test.csv", "r")
    var csv = reader.read(3)
    var data = csv.get(0, 0)
    print(data)


fn csv_writer() raises:
    var writer = CSVWriter("test.csv", "w")
    _ = writer.write(Bytes("Hello,World,I am here"))
    writer.flush()


fn main() raises:
    # write_csv()
    # read_csv()
    csv_reader()
    csv_writer()