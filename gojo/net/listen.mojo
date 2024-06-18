from .address import resolve_internet_addr, BaseAddr
from ..syscall import SocketOptions


fn listen(network: String, address: String) raises -> TCPListener:
    var tcp_addr: TCPAddr
    var err: Error
    tcp_addr, err = resolve_internet_addr(network, address)
    if err:
        raise err
    var socket = Socket(local_address=BaseAddr(tcp_addr.ip, tcp_addr.port, tcp_addr.zone))
    socket.bind(tcp_addr.ip, tcp_addr.port)
    socket.set_socket_option(SocketOptions.SO_REUSEADDR, 1)
    socket.listen()
    print(str("Listening on ") + str(socket.local_address_as_tcp()))
    return TCPListener(socket^, network, address)


trait Listener(Movable):
    # Raising here because a Result[Optional[Connection], Error] is funky.
    fn accept[T: Conn](self) raises -> T:
        ...

    fn close(inout self) -> Error:
        ...

    fn addr(self) raises -> TCPAddr:
        ...
