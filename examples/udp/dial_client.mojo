from gojo.net import Socket, HostPort, dial_udp, UDPAddr
from gojo.syscall import SocketType
import gojo.io


fn main() raises:
    # Create UDP Connection
    alias message = String("dial")
    alias host = "127.0.0.1"
    alias port = 12000
    var udp = dial_udp("udp", host, port)

    # Send 10 test messages
    for _ in range(10):
        bytes_sent = udp.write_to(message.as_bytes(), host, port)
        print("Message sent:", message, bytes_sent)

        var bytes = List[UInt8, True](capacity=16)
        try:
            _ = udp.read_from(bytes)
        except e:
            if str(e) != str(io.EOF):
                raise e

        bytes.append(0)
        print("Message received:", String(bytes^))
