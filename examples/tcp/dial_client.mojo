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
        var bytes_written: Int
        var err: Error
        bytes_written, err = connection.write(
            String("GET / HTTP/1.1\r\nHost: www.example.com\r\nConnection: close\r\n\r\n").as_bytes()
        )
        if err:
            raise err

        if bytes_written == 0:
            print("No bytes sent to peer.")
            return

        # Read the response from the connection
        var response = List[UInt8](capacity=4096)
        var bytes_read: Int = 0
        bytes_read, err = connection.read(response)
        if err and str(err) != io.EOF:
            raise err

        if bytes_read == 0:
            print("No bytes received from peer.")
            return

        response.append(0)
        print("Message received:", String(response^))

        # Cleanup the connection
        err = connection.close()
        if err:
            raise err
