from gojo.unicode.utf8.string import UnicodeString


fn main():
    var s = UnicodeString("⚔⚔⚔")
    for char in s:
        print(char)

    print(s)
    print(len(s), s.bytecount())

    print(s[0:1])
