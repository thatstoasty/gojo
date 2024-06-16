fn input(prompt: String, /) raises -> String:
    print(prompt, end="")
    var done = False
    var result = List[UInt8]()
    with open("/dev/tty", "r") as stdin:
        while not done:
            var byte = stdin.read_bytes(1)
            if byte[0] == ord("\n"):
                done = True
                continue

            result.extend(byte)

    result.append(0)
    return String(result)


fn main() raises:
    var name = input("Enter your name: ")
    print("Hello,", name)
