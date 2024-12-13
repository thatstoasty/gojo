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
    socket.connect(host, 8081)
    socket.write(message)
    print("Message sent:", message)

    var bytes = List[UInt8, True](capacity=16)
    try:
        _ = socket.read(bytes)
    except e:
        if str(e) != str(io.EOF):
            raise e

    bytes.append(0)
    var response = String(bytes^)
    print("Message received:", response)

    socket.shutdown()
    socket.close()
