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
        _ = socket.send_to(message.as_bytes(), host, port)
        print("Message sent:", message)

        try:
            bytes, _ = socket.receive_from(1024)
            bytes.append(0)
            var response = String(bytes^)
            print("Message received:", response)
        except e:
            if str(e) != str(io.EOF):
                raise e
