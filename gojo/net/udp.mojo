from ..syscall import SocketOptions
from .net import Connection, Conn
from .address import NetworkType, split_host_port, join_host_port, BaseAddr
from .socket import Socket


# TODO: Change ip to list of bytes
@value
struct UDPAddr(Addr):
    """Represents the address of a UDP end point.

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
        return NetworkType.udp.value


struct UDPConnection:
    """Implementation of the Conn interface for TCP network connections."""

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

    fn local_address(self) -> UDPAddr:
        """Returns the local network address.
        The Addr returned is shared by all invocations of local_address, so do not modify it.

        Returns:
            The local network address.
        """
        return self.socket.local_address_as_udp()

    fn remote_address(self) -> UDPAddr:
        """Returns the remote network address.
        The Addr returned is shared by all invocations of remote_address, so do not modify it.

        Returns:
            The remote network address.
        """
        return self.socket.remote_address_as_udp()


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
