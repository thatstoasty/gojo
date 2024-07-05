@value
struct UnixAddr(Addr):
    """Represents the address of a Unix domain socket end point."""

    var name: String
    var net: String

    fn network(self) -> String:
        """Returns the network type."""
        return self.net

    fn __str__(self) -> String:
        return self.name


# TODO
fn resolve_unix_addr(network: String, address: String) -> (UnixAddr, Error):
    return UnixAddr(address, network), Error()


# TODO
struct UnixConnection(Movable):
    """Connection to a Unix domain socket."""

    var socket: Socket

    fn __init__(inout self, owned socket: Socket):
        self.socket = socket^

    fn __moveinit__(inout self, owned existing: Self):
        self.socket = existing.socket^

    fn write(inout self, data: List[UInt8]) -> Error:
        """Writes data to the connection."""
        return self.socket.write(data)
