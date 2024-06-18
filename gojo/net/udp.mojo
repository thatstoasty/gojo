from ..syscall import SocketOptions, SocketType
from .net import Conn
from .address import NetworkType, split_host_port, join_host_port, BaseAddr, resolve_internet_addr
from .socket import Socket
from .listen import listen


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

    fn read_from(inout self, inout dest: List[UInt8]) -> (Int, HostPort, Error):
        """Reads data from the underlying file descriptor.

        Args:
            dest: The buffer to read data into.

        Returns:
            The number of bytes read, or an error if one occurred.
        """
        var bytes_read: Int
        var remote: HostPort
        var err: Error
        bytes_read, remote, err = self.socket.receive_from_into(dest)
        if err:
            if str(err) != io.EOF:
                return bytes_read, remote, err

        return bytes_read, remote, Error()

    fn write_to(inout self, src: List[UInt8], address: UDPAddr) -> (Int, Error):
        """Writes data to the underlying file descriptor.

        Args:
            src: The buffer to read data into.
            address: The remote peer address.

        Returns:
            The number of bytes written, or an error if one occurred.
        """
        return self.socket.send_to(src, address.ip, address.port)

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


fn _listen(network: String, address: String) raises -> UDPConnection:
    var udp_addr: TCPAddr
    var err: Error
    udp_addr, err = resolve_internet_addr(network, address)
    if err:
        raise err
    var socket = Socket(
        socket_type=SocketType.SOCK_DGRAM, local_address=BaseAddr(udp_addr.ip, udp_addr.port, udp_addr.zone)
    )
    socket.bind(udp_addr.ip, udp_addr.port)
    print(str("Listening on ") + str(socket.local_address_as_udp()))
    return UDPConnection(socket^)


fn listen_udp(network: String, local_address: UDPAddr) raises -> UDPConnection:
    """Creates a new UDP listener.

    Args:
        network: The network type.
        local_address: The local address to listen on.
    """
    return _listen(network, local_address.ip + ":" + str(local_address.port))


fn listen_udp(network: String, local_address: String) raises -> UDPConnection:
    """Creates a new UDP listener.

    Args:
        network: The network type.
        local_address: The address to listen on. The format is "host:port".
    """
    return _listen(network, local_address)
