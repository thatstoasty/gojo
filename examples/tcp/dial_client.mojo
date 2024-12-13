from gojo.net import Socket, HostPort, dial_tcp, TCPAddr
from gojo.syscall import SocketType
import gojo.io


fn main() raises:
    # Create UDP Connection
    alias message = String("dial")
    alias host = "127.0.0.1"
    alias port = 8081

    for _ in range(10):
        var connection = dial_tcp("tcp", host, port)
        connection.write("GET / HTTP/1.1\r\nHost: www.example.com\r\nConnection: close\r\n\r\n")

        # Read the response from the connection
        var response = List[UInt8, True](capacity=4096)
        try:
            bytes_read = connection.read(response)
        except e:
            if str(e) != str(io.EOF):
                raise e

        if bytes_read == 0:
            print("No bytes received from peer.")
            return

        response.append(0)
        print("Message received:", String(response^))

        # Cleanup the connection
        connection.close()
