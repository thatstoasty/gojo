from gojo.net import Socket, HostPort
from gojo.syscall import SocketType
import gojo.io


fn main() raises:
    var socket = Socket(socket_type=SocketType.SOCK_DGRAM)
    alias host = "127.0.0.1"
    alias port = 12000

    socket.bind(host, port)
    print("Listening on", str(socket.local_address_as_udp()))
    while True:
        var bytes: List[UInt8, True]
        var remote: HostPort
        var err: Error
        bytes, remote, err = socket.receive_from(1024)
        if str(err) != str(io.EOF):
            raise err

        bytes.append(0)
        var message = String(bytes^)
        print("Message Received:", message)
        message = message.upper()

        var bytes_sent: Int
        bytes_sent, err = socket.send_to(message.as_bytes_slice(), remote.host, remote.port)
        print("Message sent:", message)
