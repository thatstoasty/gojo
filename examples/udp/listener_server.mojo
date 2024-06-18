from gojo.net import UDPAddr, get_ip_address, listen_udp
from gojo.net import HostPort
import gojo.io


fn udp_listener() raises:
    var listener = listen_udp("udp", UDPAddr("127.0.0.1", 12000))

    while True:
        var dest = List[UInt8](capacity=16)
        var bytes_read: Int
        var remote: HostPort
        var err: Error
        bytes_read, remote, err = listener.read_from(dest)
        if err:
            raise err

        dest.append(0)
        var message = String(dest^)
        print("Message received:", message)
        message = message.upper()
        var bytes_sent: Int
        bytes_sent, err = listener.write_to(message.as_bytes(), UDPAddr(remote.host, remote.port))
        print("Message sent:", message)
    # var socket = Socket(socket_type=SocketType.SOCK_DGRAM)
    # socket.bind('127.0.0.1', 12000)
    # # socket.set_socket_option(SocketOptions.SO_REUSEADDR, 1)
    # print("Listening on", socket.local_address_as_udp())
    # while True:
    #     var bytes: List[UInt8]
    #     var remote: HostPort
    #     var err: Error
    #     bytes, remote, err = socket.receive_from(1024)
    #     if str(err) != io.EOF:
    #         raise err

    #     bytes.append(0)
    #     var message = String(bytes^)
    #     print("Bytes received:", len(message), "message:", message)
    #     message = message.upper()
    #     var bytes_sent: Int
    #     bytes_sent, err = socket.send_to(message.as_bytes(), remote.host, remote.port)
    #     print("Bytes sent:", bytes_sent)


fn main() raises:
    udp_listener()
