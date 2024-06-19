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
        var bytes_sent: Int
        var err: Error
        bytes_sent, err = udp.write_to(message.as_bytes(), host, port)
        print("Message sent:", message, bytes_sent)

        var bytes = List[UInt8](capacity=16)
        var bytes_received: Int
        var remote: HostPort
        bytes_received, remote, err = udp.read_from(bytes)
        if str(err) != io.EOF:
            raise err

        bytes.append(0)
        var response = String(bytes^)
        print("Message received:", response)
