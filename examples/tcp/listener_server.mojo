from gojo.net import TCPAddr, get_ip_address, listen_tcp, HostPort
import gojo.io


fn main() raises:
    var listener = listen_tcp("udp", TCPAddr("127.0.0.1", 12000))

    while True:
        var connection = listener.accept()

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
