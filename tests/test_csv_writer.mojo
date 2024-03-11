from tests.wrapper import MojoTest
from gojo.encoding.csv import new_writer
from gojo.io import FileWrapper
from gojo.builtins import Bytes


fn test_csv_writer() raises:
    # Create an File Writer and create a CSV Writer using it.
    var writer = FileWrapper("test.csv", "w+")
    var csv_writer = new_writer(writer ^)

    # Write the following lines to the CSV file
    var record = DynamicVector[String]()
    record.append("a,b,c\n1,2,3\n4,5,6\n")
    _ = csv_writer.write(record)


fn main() raises:
    test_csv_writer()