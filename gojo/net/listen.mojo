# TODO: For now listener is paired with TCP until we need to support
# more than one type of Connection or Listener
@value
struct ListenConfig(CollectionElement):
    var keep_alive: Duration

    fn listen(self, network: String, address: String) raises -> TCPListener:
        var tcp_addr = resolve_internet_addr(network, address)
        var socket = Socket(local_address=tcp_addr)
        socket.bind(tcp_addr.ip, tcp_addr.port)
        socket.set_socket_option(SocketOptions.SO_REUSEADDR, 1)
        socket.listen()
        print(str("Listening on ") + str(socket.local_address))
        return TCPListener(socket^, self, network, address)


trait Listener(Movable):
    # Raising here because a Result[Optional[Connection], Error] is funky.
    fn accept(self) raises -> Connection:
        ...

    fn close(inout self) -> Error:
        ...

    fn addr(self) raises -> TCPAddr:
        ...
