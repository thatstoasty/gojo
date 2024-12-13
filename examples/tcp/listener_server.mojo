from gojo.net import TCPAddr, get_ip_address, listen_tcp, HostPort
import gojo.io


fn main() raises:
    var listener = listen_tcp("udp", TCPAddr("127.0.0.1", 12000))

    while True:
        var connection = listener.accept()

        # Read the contents of the message from the client.
        var bytes = List[UInt8, True](capacity=4096)
        try:
            _ = connection.read(bytes)
        except e:
            if str(e) != str(io.EOF):
                raise e

        bytes.append(0)
        var message = String(bytes^)
        print("Message Received:", message)
        message = message.upper()

        # Send a response back to the client.
        connection.write(message)
        print("Message sent:", message)
