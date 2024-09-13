from gojo.net import Socket, HostPort
from gojo.syscall import SocketOptions
import gojo.io


fn main() raises:
    var socket = Socket()
    socket.set_socket_option(SocketOptions.SO_REUSEADDR, 1)
    alias host = "127.0.0.1"
    alias port = 8081

    # Bind server to port 8081
    socket.bind(host, port)
    socket.listen()
    print("Listening on", str(socket.local_address_as_tcp()))
    while True:
        # Accept connections from clients and serve them.
        var connection = socket.accept()
        print("Serving", str(connection.remote_address_as_tcp()))

        # Read the contents of the message from the client.
        var bytes = List[UInt8, True](capacity=4096)
        var bytes_read: Int
        var err: Error
        bytes_read, err = connection.read(bytes)
        if str(err) != str(io.EOF):
            raise err

        bytes.append(0)
        var message = String(bytes^)
        print("Message Received:", message)
        message = message.upper()

        # Send a response back to the client.
        var bytes_sent: Int
        bytes_sent, err = connection.write(message.as_bytes())
        print("Message sent:", message, bytes_sent)
        err = connection.close()
        if err:
            raise err
