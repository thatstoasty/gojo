from ..syscall import SocketOptions
from .net import Conn
from .address import NetworkType, split_host_port, join_host_port, BaseAddr, resolve_internet_addr, HostPort
from .socket import Socket
from .listen import listen, Listener


@value
struct TCPAddr(Addr):
    """Addr struct representing a TCP address.

    Args:
        ip: IP address.
        port: Port number.
        zone: IPv6 addressing zone.
    """

    var ip: String
    var port: Int
    var zone: String  # IPv6 addressing zone

    fn __init__(inout self, ip: String = "127.0.0.1", port: Int = 8000, zone: String = ""):
        self.ip = ip
        self.port = port
        self.zone = zone

    fn __init__(inout self, addr: BaseAddr):
        self.ip = addr.ip
        self.port = addr.port
        self.zone = addr.zone

    fn __str__(self) -> String:
        if self.zone != "":
            return join_host_port(str(self.ip) + "%" + self.zone, str(self.port))
        return join_host_port(self.ip, str(self.port))

    fn network(self) -> String:
        return NetworkType.tcp.value


struct TCPConnection:
    """TCPConn is an implementation of the Conn interface for TCP network connections.

    Args:
        connection: The underlying Connection.
    """

    var socket: Socket

    fn __init__(inout self, owned socket: Socket):
        self.socket = socket^

    fn __moveinit__(inout self, owned existing: Self):
        self.socket = existing.socket^

    fn read(inout self, inout dest: List[UInt8]) -> (Int, Error):
        """Reads data from the underlying file descriptor.

        Args:
            dest: The buffer to read data into.

        Returns:
            The number of bytes read, or an error if one occurred.
        """
        var bytes_read: Int
        var err: Error
        bytes_read, err = self.socket.read(dest)
        if err:
            if str(err) != io.EOF:
                return bytes_read, err

        return bytes_read, Error()

    fn write(inout self, src: List[UInt8]) -> (Int, Error):
        """Writes data to the underlying file descriptor.

        Args:
            src: The buffer to read data into.

        Returns:
            The number of bytes written, or an error if one occurred.
        """
        return self.socket.write(src)

    fn close(inout self) -> Error:
        """Closes the underlying file descriptor.

        Returns:
            An error if one occurred, or None if the file descriptor was closed successfully.
        """
        return self.socket.close()

    fn local_address(self) -> TCPAddr:
        """Returns the local network address.
        The Addr returned is shared by all invocations of local_address, so do not modify it.

        Returns:
            The local network address.
        """
        return self.socket.local_address_as_tcp()

    fn remote_address(self) -> TCPAddr:
        """Returns the remote network address.
        The Addr returned is shared by all invocations of remote_address, so do not modify it.

        Returns:
            The remote network address.
        """
        return self.socket.remote_address_as_tcp()


fn listen_tcp(network: String, local_address: TCPAddr) raises -> TCPListener:
    """Creates a new TCP listener.

    Args:
        network: The network type.
        local_address: The local address to listen on.
    """
    return listen(network, local_address.ip + ":" + str(local_address.port))


fn listen_tcp(network: String, local_address: String) raises -> TCPListener:
    """Creates a new TCP listener.

    Args:
        network: The network type.
        local_address: The address to listen on. The format is "host:port".
    """
    return listen(network, local_address)


struct TCPListener:
    var socket: Socket
    var network_type: String
    var address: String

    fn __init__(
        inout self,
        owned socket: Socket,
        network_type: String,
        address: String,
    ):
        self.socket = socket^
        self.network_type = network_type
        self.address = address

    fn __moveinit__(inout self, owned existing: Self):
        self.socket = existing.socket^
        self.network_type = existing.network_type^
        self.address = existing.address^

    fn listen(self) raises -> Self:
        return listen(self.network_type, self.address)

    fn accept(self) raises -> TCPConnection:
        return TCPConnection(self.socket.accept())

    fn close(inout self) -> Error:
        return self.socket.close()

    fn addr(self) raises -> TCPAddr:
        var result = resolve_internet_addr(self.network_type, self.address)
        if result[1]:
            raise result[1]

        return result[0]


fn dial_tcp(network: String, remote_address: TCPAddr) raises -> TCPConnection:
    """Connects to the address on the named network.

    The network must be "tcp", "tcp4", or "tcp6".
    Args:
        network: The network type.
        remote_address: The remote address to connect to.

    Returns:
        The TCP connection.
    """
    # TODO: Add conversion of domain name to ip address
    return Dialer(remote_address).dial(network, remote_address.ip + ":" + str(remote_address.port))


fn dial_tcp(network: String, remote_address: String) raises -> TCPConnection:
    """Connects to the address on the named network.

    The network must be "tcp", "tcp4", or "tcp6".
    Args:
        network: The network type.
        remote_address: The remote address to connect to.

    Returns:
        The TCP connection.
    """
    var address: HostPort
    var err: Error
    address, err = split_host_port(remote_address)
    if err:
        raise err
    return Dialer(TCPAddr(address.host, address.port)).dial(network, remote_address)
