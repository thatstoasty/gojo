from ..syscall import SocketOptions
from .net import Connection, Conn
from .address import NetworkType, split_host_port, join_host_port
from .socket import Socket


# TODO: Change ip to list of bytes
@value
struct TCPAddr(Addr):
    """Represents the address of a UDP end point.

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
        return NetworkType.udp.value


struct UDPConnection(Conn):
    """Implementation of the Conn interface for UDP network connections.

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


fn listen_udp(network: String, local_address: TCPAddr) raises -> UDPConnection:
    """Creates a new UDP listener.

    Args:
        network: The network type.
        local_address: The local address to listen on.
    """
    return ListenConfig(DEFAULT_TCP_KEEP_ALIVE).listen(network, local_address.ip + ":" + str(local_address.port))


fn listen_udp(network: String, local_address: String) raises -> UDPConnection:
    """Creates a new UDP listener.

    Args:
        network: The network type.
        local_address: The address to listen on. The format is "host:port".
    """
    return ListenConfig(DEFAULT_TCP_KEEP_ALIVE).listen(network, local_address)
