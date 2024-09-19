from gojo.net import Socket, HostPort
from gojo.syscall import SocketType
import gojo.io


fn main() raises:
    # Create UDP Socket
    var socket = Socket(socket_type=SocketType.SOCK_DGRAM)
    alias message = String("test")
    alias host = "127.0.0.1"
    alias port = 12000

    # Send 10 test messages
    for _ in range(10):
        var bytes_sent: Int
        var err: Error
        bytes_sent, err = socket.send_to(message.as_bytes(), host, port)
        print("Message sent:", message)

        var bytes: List[UInt8, True]
        var remote: HostPort
        bytes, remote, err = socket.receive_from(1024)
        if str(err) != str(io.EOF):
            raise err

        bytes.append(0)
        var response = String(bytes^)
        print("Message received:", response)
