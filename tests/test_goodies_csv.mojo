from tests.wrapper import MojoTest
from gojo.builtins import Bytes
# from external.csv import CsvBuilder, CsvTable
# from goodies import FileWrapper, CSVReader, CSVWriter


# fn write_csv() raises:
#     var file = FileWrapper("test.csv", "w")
#     var csv = CsvBuilder(3)
#     csv.push("Hello")
#     csv.push("World")
#     csv.push("I am here", True)

#     var csv_text = csv^.finish()
#     _ = file.write(csv_text)


# fn read_csv() raises:
#     with open("test.csv", "r") as file:
#         var builder = CsvBuilder(3)
#         builder.push(file.read())
#         var csv_text = builder^.finish()
#         var csv = CsvTable(csv_text)
#         var data = csv.get(0, 0)
#         print(data)


# fn test_csv_reader() raises:
#     var test = MojoTest("Testing goodies.CSVReader")
#     var file = FileWrapper("tests/data/test_read.csv", "r")
#     var reader = CSVReader(file ^)
#     var csv = reader.read_lines(3, "\n", 3)
#     test.assert_equal(csv.get(0, 0), "Hello")
#     test.assert_equal(csv.get(1, 0), "Goodbye")
#     test.assert_equal(csv.get(2, 2), "Dolor")


# fn test_csv_reader_buffered_read() raises:
#     var test = MojoTest("Testing goodies.CSVReader read bigger than buffer size")
#     var file = FileWrapper("tests/data/test_big_read.csv", "r")
#     var reader = CSVReader(file ^)
#     var csv = reader.read_lines(201, "\n", column_count=3)
#     test.assert_equal(csv.get(200, 0), "Hello")


# fn test_csv_writer() raises:
#     var test = MojoTest("Testing goodies.CSVWriter")
    
#     # Build CSV dataframe like structure and write to file
#     var builder = CsvBuilder("a", "b", "c")
#     for i in range(10):
#         builder.push("Hello")
#         builder.push("World")
#         builder.push("I am here")
#     var csv = CsvTable(builder^.finish())
#     var file = FileWrapper("tests/data/test_write.csv", "w")
#     var writer = CSVWriter(file ^)
#     var bytes_written = writer.write(csv)

#     test.assert_equal(bytes_written, 237)


fn main() raises:
    # TODO: 24.2 broke mojo-csv, need updates from maintainer but if I can make them myself ill submit a PR to the repo.
    pass
    # test_csv_reader()
    # test_csv_reader_buffered_read()
    # test_csv_writer()