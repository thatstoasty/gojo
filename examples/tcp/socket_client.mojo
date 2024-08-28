from gojo.net import Socket, HostPort
from gojo.syscall import SocketType
import gojo.io


fn main() raises:
    # Create TCP Socket
    var socket = Socket()
    alias message = String("test")
    alias host = "127.0.0.1"
    alias port = 8082

    # Bind client to port 8082
    socket.bind(host, port)

    # Send 10 test messages
    var err = socket.connect(host, 8081)
    if err:
        raise err
    var bytes_sent: Int
    bytes_sent, err = socket.write(message.as_bytes())
    print("Message sent:", message)

    var bytes = List[UInt8](capacity=16)
    var bytes_read: Int
    bytes_read, err = socket.read(bytes)
    if str(err) != str(io.EOF):
        raise err

    bytes.append(0)
    var response = String(bytes^)
    print("Message received:", response)

    _ = socket.shutdown()
    _ = socket.close()
