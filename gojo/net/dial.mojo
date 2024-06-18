from .tcp import resolve_internet_addr
from .socket import Socket
from .address import split_host_port, BaseAddr


@value
struct Dialer:
    var local_address: TCPAddr

    @always_inline
    fn dial(self, network: String, address: String) raises -> TCPConnection:
        var tcp_addr: TCPAddr
        var err: Error
        tcp_addr, err = resolve_internet_addr(network, address)
        if err:
            raise err
        var socket = Socket(local_address=BaseAddr(tcp_addr.ip, tcp_addr.port, tcp_addr.zone))
        socket.connect(tcp_addr.ip, tcp_addr.port)
        return TCPConnection(socket^)
