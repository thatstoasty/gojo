from gojo.net import UDPAddr, get_ip_address, listen_udp, HostPort
import gojo.io


fn main() raises:
    var listener = listen_udp("udp", UDPAddr("127.0.0.1", 12000))

    while True:
        var dest = List[UInt8, True](capacity=16)
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
