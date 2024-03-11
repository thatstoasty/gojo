import ...bufio
import ...io
from .reader import valid_delim, ERR_INVALID_DELIM


alias SPECIAL_CHARACTERS = ['\n', '\r', '\"']


fn index_of_special_characters(string: String) -> Int:
    for i in range(len(string)):
        if string[i] == SPECIAL_CHARACTERS.get[0, StringLiteral]():
            return i
        elif string[i] == SPECIAL_CHARACTERS.get[1, StringLiteral]():
            return i
        elif string[i] == SPECIAL_CHARACTERS.get[2, StringLiteral]():
            return i
    return -1


fn contains_special_characters(string: String) -> Bool:
    for i in range(len(string)):
        if string[i] == SPECIAL_CHARACTERS.get[0, StringLiteral]():
            return True
        elif string[i] == SPECIAL_CHARACTERS.get[1, StringLiteral]():
            return True
        elif string[i] == SPECIAL_CHARACTERS.get[2, StringLiteral]():
            return True
    return False


# fn rune_self() -> String:
#     pass


# A Writer writes records using CSV encoding.
#
# As returned by [new_writer], a Writer writes records terminated by a
# newline and uses ',' as the field delimiter. The exported fields can be
# changed to customize the details before
# the first call to [Writer.Write] or [Writer.write_all].
#
# [Writer.comma] is the field delimiter.
#
# If [Writer.use_crlf] is True,
# the Writer ends each output line with \r\n instead of \n.
#
# The writes of individual records are buffered.
# After all data has been written, the client should call the
# [Writer.flush] method to guarantee all data has been forwarded to
# the underlying [io.Writer].  Any errors that occurred should
# be checked by calling the [Writer.Error] method.
struct Writer[W: io.Writer]():
    var delimiter: String # Field delimiter (set to ',' by new_writer)
    var use_crlf: Bool # True to use \r\n as the line terminator
    var writer: bufio.Writer[W]

    # fn __init__(
    #     inout self,
    #     writer: bufio.Writer[W],
    #     comma: String = ",",
    #     use_crlf: Bool = False,
    # ):
    #     self.delimiter = comma
    #     self.writer = writer ^
    #     self.use_crlf = use_crlf

    fn __init__(
        inout self,
        writer: W,
        comma: String = ",",
        use_crlf: Bool = False,
    ):
        self.delimiter = comma
        self.writer = bufio.new_writer(writer ^)
        self.use_crlf = use_crlf
    
    # write writes a single CSV record to w along with any necessary quoting.
    # A record is a slice of strings with each string being one field.
    # Writes are buffered, so [Writer.flush] must eventually be called to ensure
    # that the record is written to the underlying [io.Writer].
    fn write(inout self, record: DynamicVector[String]) raises:
        if not valid_delim(self.delimiter):
            raise Error(ERR_INVALID_DELIM)

        for i in range(len(record)):
            var field = record[i]
            if i > 0:
                _ = self.writer.write_string(self.delimiter)
            
            # If we don't have to have a quoted field then just
            # write out the field and continue to the next field.
            if not self.field_needs_quotes(field):
                _ = self.writer.write_string(field)
    
            _ = self.writer.write_byte(ord('"'))

            while len(field) > 0:
                # Search for special characters.
                i = index_of_special_characters(field)
                if i < 0:
                    i = len(field)
        
                # Copy verbatim everything before the special character.
                _ = self.writer.write_string(field[:i])
                field = field[i:]

                # Encode the special character.
                if len(field) > 0:
                    if field[0] == '"':
                        _ = self.writer.write_string('""')
                    elif field[0] == '\r':
                        if not self.use_crlf:
                            _ = self.writer.write_byte(ord('\r'))
                    elif field[0] == '\n':
                        if self.use_crlf:
                            _ = self.writer.write_string("\r\n")
                        else:
                            _ = self.writer.write_byte(ord('\n'))
                    else:
                        _ = self.writer.write_byte(ord(field[0]))

        if self.use_crlf:
            _ = self.writer.write_string("\r\n")
        else:
            _ = self.writer.write_byte(ord('\n'))

    # flush writes any buffered data to the underlying [io.Writer].
    # To check if an error occurred during flush, call [Writer.Error].
    fn flush(inout self) raises:
        self.writer.flush()

    # write_all writes multiple CSV records to w using [Writer.Write] and
    # then calls [Writer.flush], returning any error from the flush.
    fn write_all(inout self, records: DynamicVector[DynamicVector[String]]) raises:
        for record in records:
            _ = self.write(record[])
        return self.writer.flush()

    # field_needs_quotes reports whether our field must be enclosed in quotes.
    # Fields with a comma, fields with a quote or newline, and
    # fields which start with a space must be enclosed in quotes.
    # We used to quote empty strings, but we do not anymore (as of Go 1.4).
    # The two representations should be equivalent, but Postgres distinguishes
    # quoted vs non-quoted empty string during database imports, and it has
    # an option to force the quoted behavior for non-quoted CSV but it has
    # no option to force the non-quoted behavior for quoted CSV, making
    # CSV with quoted empty strings strictly less useful.
    # Not quoting the empty string also makes this package match the behavior
    # of Microsoft Excel and Google Drive.
    # For Postgres, quote the data terminating string `\.`.
    fn field_needs_quotes(self, field: String) -> Bool:
        if field == "":
            return False

        if field == "\\.":
            return True

        # TODO: Not supporting runes yet, so all characters are assumed to be one byte
        # if self.delimiter < rune_self():
        var i = 0
        while i < len(field):
            var c = field[i]
            if c == self.delimiter or c == '"' or c == '\n' or c == '\r':
                return True
            else:
                if self.delimiter in field or contains_special_characters(field):
                    return True
            i += 1
    
        # var r1 = decode_rune_in_string(field)
        # return is_space(field)
        return field == " "


# new_writer returns a new Writer that writes to self.
fn new_writer[W: io.Writer](owned writer: W) -> Writer[W]:
    return Writer(
        comma=',',
        writer=bufio.new_writer(writer ^),
    )
