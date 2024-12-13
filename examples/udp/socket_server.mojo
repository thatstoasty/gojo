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
        var message: String
        var remote: HostPort
        try:
            bytes, remote = socket.receive_from(1024)
            bytes.append(0)
            message = String(bytes^)
        except e:
            if str(e) != str(io.EOF):
                raise e

        print("Message Received:", message)
        message = message.upper()

        _ = socket.send_to(message.as_bytes(), remote.host, remote.port)
        print("Message sent:", message)
