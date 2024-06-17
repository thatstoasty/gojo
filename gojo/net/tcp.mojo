from ..syscall import SocketOptions
from .net import Connection, Conn
from .address import NetworkType, split_host_port, join_host_port
from .socket import Socket
from .listen import ListenConfig


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

    fn __init__(inout self):
        self.ip = String("127.0.0.1")
        self.port = 8000
        self.zone = ""

    fn __init__(inout self, ip: String, port: Int):
        self.ip = ip
        self.port = port
        self.zone = ""

    fn __str__(self) -> String:
        if self.zone != "":
            return join_host_port(str(self.ip) + "%" + self.zone, str(self.port))
        return join_host_port(self.ip, str(self.port))

    fn network(self) -> String:
        return NetworkType.tcp.value


fn resolve_internet_addr(network: String, address: String) raises -> TCPAddr:
    var host: String = ""
    var port: String = ""
    var portnum: Int = 0
    if (
        network == NetworkType.tcp.value
        or network == NetworkType.tcp4.value
        or network == NetworkType.tcp6.value
        or network == NetworkType.udp.value
        or network == NetworkType.udp4.value
        or network == NetworkType.udp6.value
    ):
        if address != "":
            var host_port = split_host_port(address)
            host = host_port.host
            port = str(host_port.port)
            portnum = atol(str(port))
    elif network == NetworkType.ip.value or network == NetworkType.ip4.value or network == NetworkType.ip6.value:
        if address != "":
            host = address
    elif network == NetworkType.unix.value:
        raise Error("Unix addresses not supported yet")
    else:
        raise Error("unsupported network type: " + network)
    return TCPAddr(host, portnum)


struct TCPConnection(Conn):
    """TCPConn is an implementation of the Conn interface for TCP network connections.

    Args:
        connection: The underlying Connection.
    """

    var _connection: Connection

    fn __init__(inout self, owned connection: Connection):
        self._connection = connection^

    fn __init__(inout self, owned socket: Socket):
        self._connection = Connection(socket^)

    fn __moveinit__(inout self, owned existing: Self):
        self._connection = existing._connection^

    fn read(inout self, inout dest: List[UInt8]) -> (Int, Error):
        """Reads data from the underlying file descriptor.

        Args:
            dest: The buffer to read data into.

        Returns:
            The number of bytes read, or an error if one occurred.
        """
        var bytes_read: Int
        var err: Error
        bytes_read, err = self._connection.read(dest)
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
        return self._connection.write(src)

    fn close(inout self) -> Error:
        """Closes the underlying file descriptor.

        Returns:
            An error if one occurred, or None if the file descriptor was closed successfully.
        """
        return self._connection.close()

    fn local_address(self) -> TCPAddr:
        """Returns the local network address.
        The Addr returned is shared by all invocations of local_address, so do not modify it.

        Returns:
            The local network address.
        """
        return self._connection.local_address()

    fn remote_address(self) -> TCPAddr:
        """Returns the remote network address.
        The Addr returned is shared by all invocations of remote_address, so do not modify it.

        Returns:
            The remote network address.
        """
        return self._connection.remote_address()


fn listen_tcp(network: String, local_address: TCPAddr) raises -> TCPListener:
    """Creates a new TCP listener.

    Args:
        network: The network type.
        local_address: The local address to listen on.
    """
    return ListenConfig(DEFAULT_TCP_KEEP_ALIVE).listen(network, local_address.ip + ":" + str(local_address.port))


fn listen_tcp(network: String, local_address: String) raises -> TCPListener:
    """Creates a new TCP listener.

    Args:
        network: The network type.
        local_address: The address to listen on. The format is "host:port".
    """
    return ListenConfig(DEFAULT_TCP_KEEP_ALIVE).listen(network, local_address)


struct TCPListener(Listener):
    var _file_descriptor: Socket
    var listen_config: ListenConfig
    var network_type: String
    var address: String

    fn __init__(
        inout self,
        owned file_descriptor: Socket,
        listen_config: ListenConfig,
        network_type: String,
        address: String,
    ):
        self._file_descriptor = file_descriptor^
        self.listen_config = listen_config
        self.network_type = network_type
        self.address = address

    fn __moveinit__(inout self, owned existing: Self):
        self._file_descriptor = existing._file_descriptor^
        self.listen_config = existing.listen_config^
        self.network_type = existing.network_type^
        self.address = existing.address^

    fn listen(self) raises -> Self:
        return self.listen_config.listen(self.network_type, self.address)

    fn accept(self) raises -> Connection:
        return Connection(self._file_descriptor.accept())

    fn accept_tcp(self) raises -> TCPConnection:
        return TCPConnection(self._file_descriptor.accept())

    fn close(inout self) -> Error:
        return self._file_descriptor.close()

    fn addr(self) raises -> TCPAddr:
        return resolve_internet_addr(self.network_type, self.address)


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
    var address = split_host_port(remote_address)
    return Dialer(TCPAddr(address.host, address.port)).dial(network, remote_address)
