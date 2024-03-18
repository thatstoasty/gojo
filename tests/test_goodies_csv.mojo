from gojo.builtins import Bytes
from external.csv import CsvBuilder, CsvTable
from goodies import FileWrapper, CSVReader, CSVWriter


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
    var file = FileWrapper("tests/data/test_read.csv", "r")
    var reader = CSVReader(file ^)
    var csv = reader.read_lines(3, "\n", 3)
    print(csv._inner_string)
    var data = csv.get(0, 0)
    print(data)


fn csv_writer() raises:
    var writer = CSVWriter("tests/data/test_write.csv", "w")
    _ = writer.write(Bytes("Hello,World,I am here"))
    writer.flush()


fn main() raises:
    # write_csv()
    # read_csv()
    csv_reader()
    csv_writer()