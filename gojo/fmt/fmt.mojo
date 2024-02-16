"""Formatting options
General
%v	the value in a default format
    when printing structs, the plus flag (%+v) adds field names

Boolean
%t	the word true or false

Integer
%b	base 2

Floating-point and complex constituents:
%f	decimal point but no exponent, e.g. 123.456

String and slice of bytes (treated equivalently with these verbs):
%s	the uninterpreted bytes of the string or slice
%q	a double-quoted string safely escaped with Go syntax

The default formatting for %v is:
bool:                    %t
int, int8 etc.:          %d
uint, uint8 etc.:        %d, %#x if printed with %#v
float32, complex64, etc: %g
string:                  %s
chan:                    %p
pointer:                 %p
"""

from utils.variant import Variant


alias Args = Variant[String, Int, Float64, Bool]


fn replace_first(s: String, old: String, new: String) -> String:
    """Replace the first occurrence of a substring in a string.

    Parameters:
    s (str): The original string
    old (str): The substring to be replaced
    new (str): The new substring

    Returns:
    String: The string with the first occurrence of the old substring replaced by the new one.
    """
    # Find the first occurrence of the old substring
    var index = s.find(old)

    # If the old substring is found, replace it
    if index != -1:
        return s[:index] + new + s[index + len(old):]

    # If the old substring is not found, return the original string
    return s


fn format_string(s: String, arg: String) -> String:
    return replace_first(s, String("%s"), arg)


fn format_integer(s: String, arg: Int) -> String:
    return replace_first(s, String("%d"), arg)


fn format_float(s: String, arg: Float64) -> String:
    return replace_first(s, String("%f"), arg)


fn format_boolean(s: String, arg: Bool) -> String:
    var value: String = ""
    if arg:
        value = "True"
    else:
        value = "False"

    return replace_first(s, String("%t"), value)


fn sprintf(formatting: String, *args: Args) raises -> String:
    var text = formatting
    let formatter_count = formatting.count("%")

    if formatter_count > len(args):
        raise Error("Not enough arguments for format string")
    elif formatter_count < len(args):
        raise Error("Too many arguments for format string")

    for i in range(len(args)):
        var argument = args[i]
        if argument.isa[String]():
            text = format_string(text, argument.get[String]())
        elif argument.isa[Int]():
            text = format_integer(text, argument.get[Int]())
        elif argument.isa[Float64]():
            text = format_float(text, argument.get[Float64]())
        elif argument.isa[Bool]():
            text = format_boolean(text, argument.get[Bool]())
        else:
            raise Error("Unknown for argument #" + String(i))

    return text


# fn main() raises:
#     let s = sprintf("Hello, %s. I am %d years old. More precisely, I am %f years old. It is %t that I like Mojo!", String("world"), 29, Float64(29.5), True)
#     print(s)