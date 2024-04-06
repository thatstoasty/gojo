from .tcp import TCPAddr, TCPConnection, resolve_internet_addr
from .socket import Socket


@value
struct Dialer():
    var local_address: TCPAddr

    fn dial(self, network: String, address: String) raises -> TCPConnection:
        var tcp_addr = resolve_internet_addr(network, address)
        var socket = Socket(local_address=self.local_address)
        socket.connect(tcp_addr.ip, tcp_addr.port)
        print(String("Connected to ") + socket.remote_address)
        return TCPConnection(socket ^)


fn dial_tcp(network: String, local_address: TCPAddr) raises -> TCPConnection:
    # TODO: Add conversion of domain name to ip address
    return Dialer(local_address).dial(
        network, local_address.ip + ":" + str(local_address.port)
    )


fn dial_tcp(network: String, ip: String, port: Int) raises -> TCPConnection:
    return Dialer(TCPAddr(ip, port)).dial(network, ip + ":" + str(port))
