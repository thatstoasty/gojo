from .tcp import resolve_internet_addr
from .socket import Socket
from .address import split_host_port


@value
struct Dialer:
    var local_address: TCPAddr

    @always_inline
    fn dial(self, network: String, address: String) raises -> TCPConnection:
        var tcp_addr = resolve_internet_addr(network, address)
        var socket = Socket(local_address=self.local_address)
        socket.connect(tcp_addr.ip, tcp_addr.port)
        return TCPConnection(socket^)
