from memory import Span
from collections import InlineList
from ..syscall import SocketOptions
from .address import NetworkType, split_host_port, join_host_port, BaseAddr, resolve_internet_addr, HostPort
from .socket import Socket
from memory import UnsafePointer


@value
struct TCPAddr(Addr):
    """Addr struct representing a TCP address.

    Args:
        ip: IP address.
        port: Port number.
        zone: IPv6 addressing zone.
    """

    var ip: String
    """IP address."""
    var port: Int
    """Port number."""
    var zone: String  # IPv6 addressing zone
    """IPv6 addressing zone."""

    fn __init__(out self, ip: String = "127.0.0.1", port: Int = 8000, zone: String = ""):
        """Initializes a new TCP address.

        Args:
            ip: IP address.
            port: Port number.
            zone: IPv6 addressing zone.
        """
        self.ip = ip
        self.port = port
        self.zone = zone

    fn __init__(out self, host_port: HostPort, zone: String = ""):
        """Initializes a new TCP address.

        Args:
            host_port: The host and port.
            zone: IPv6 addressing zone.
        """
        self.ip = host_port.host
        self.port = host_port.port
        self.zone = zone

    fn __init__(out self, addr: BaseAddr):
        """Initializes a new TCP address.

        Args:
            addr: The base address.
        """
        self.ip = addr.ip
        self.port = addr.port
        self.zone = addr.zone

    fn __str__(self) -> String:
        """Returns the string representation of the TCP address.

        Returns:
            The string representation of the TCP address.
        """
        if self.zone != "":
            return join_host_port(str(self.ip) + "%" + self.zone, str(self.port))
        return join_host_port(self.ip, str(self.port))

    fn network(self) -> String:
        """Returns the network type.

        Returns:
            The network type.
        """
        return NetworkType.tcp.value


struct TCPConnection(Movable):
    """TCPConn is an implementation of the Conn interface for TCP network connections.

    Args:
        connection: The underlying Connection.
    """

    var socket: Socket
    """The underlying socket."""

    fn __init__(out self, owned socket: Socket):
        """Initializes a new TCP connection.

        Args:
            socket: The underlying socket.
        """
        self.socket = socket^

    fn __moveinit__(out self, owned existing: Self):
        """Initializes a new TCP connection by moving the data from `existing`.

        Args:
            existing: The existing TCP connection.
        """
        self.socket = existing.socket^

    fn _read(mut self, dest: UnsafePointer[Byte], capacity: Int) raises -> Int:
        """Reads data from the underlying file descriptor.

        Args:
            dest: The buffer to read data into.
            capacity: The capacity of the destination buffer.

        Returns:
            The number of bytes read, or an error if one occurred.

        Raises:
            Error: If there is no space left in the destination buffer or failed to read from the file descriptor.
        """
        return self.socket._read(dest, capacity)

    fn read(mut self, mut dest: List[Byte, True]) raises -> Int:
        """Reads data from the underlying file descriptor.

        Args:
            dest: The buffer to read data into.

        Returns:
            The number of bytes read, or an error if one occurred.

        Raises:
            Error: If there is no space left in the destination buffer or failed to read from the file descriptor.
        """
        if dest.size == dest.capacity:
            raise Error("TCPConnection.read: no space left in destination buffer.")

        bytes_read = self._read(dest.unsafe_ptr().offset(len(dest)), dest.capacity - dest.size)
        dest.size += bytes_read

        return bytes_read

    @always_inline
    fn write_bytes(mut self, bytes: Span[Byte]) -> None:
        """Write a `Span[Byte]` to this `Writer`.

        Args:
            bytes: The string slice to write to this Writer. Must NOT be null-terminated.
        """
        self.socket.write_bytes(bytes)

    fn write[*Ts: Writable](mut self, *args: *Ts) -> None:
        """Write data to the File Descriptor.

        Parameters:
            Ts: The types of data to write.

        Args:
            args: The data to write.
        """

        @parameter
        fn write_arg[T: Writable](arg: T):
            arg.write_to(self)

        args.each[write_arg]()

    fn close(mut self) raises -> None:
        """Closes the underlying file descriptor.

        Raises:
            Error: If an error occurred while closing the file descriptor.
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

    Returns:
        The TCP listener.

    Raises:
        Error: If the network type is not supported or failed to bind the socket.
    """
    socket = Socket()
    socket.bind(local_address.ip, local_address.port)
    socket.set_socket_option(SocketOptions.SO_REUSEADDR, 1)
    socket.listen()
    # print(str("Listening on ") + str(socket.local_address_as_tcp()))
    return TCPListener(socket^, network, local_address)


fn listen_tcp(network: String, local_address: String) raises -> TCPListener:
    """Creates a new TCP listener.

    Args:
        network: The network type.
        local_address: The address to listen on. The format is "host:port".

    Returns:
        The TCP listener.

    Raises:
        Error: If the network type is not supported or failed to bind the socket.
    """
    return listen_tcp(network, resolve_internet_addr(network, local_address))


fn listen_tcp(network: String, host: String, port: Int) raises -> TCPListener:
    """Creates a new TCP listener.

    Args:
        network: The network type.
        host: The address to listen on, in ipv4 format.
        port: The port to listen on.

    Returns:
        The TCP listener.

    Raises:
        Error: If the network type is not supported or failed to bind the socket.
    """
    return listen_tcp(network, TCPAddr(host, port))


struct TCPListener:
    """TCP network listener."""

    var socket: Socket
    """The underlying socket."""
    var network_type: String
    """The network type."""
    var address: TCPAddr
    """The address to listen on."""

    fn __init__(
        out self,
        owned socket: Socket,
        network_type: String,
        address: TCPAddr,
    ):
        """Initializes a new TCP listener.

        Args:
            socket: The underlying socket.
            network_type: The network type.
            address: The address to listen on.
        """
        self.socket = socket^
        self.network_type = network_type
        self.address = address

    fn __moveinit__(out self, owned existing: Self):
        """Initializes a new TCP listener by moving the data from `existing`.

        Args:
            existing: The existing TCP listener.
        """

        self.socket = existing.socket^
        self.network_type = existing.network_type^
        self.address = existing.address^

    fn accept(self) raises -> TCPConnection:
        """Accepts a new connection.

        Returns:
            The TCP connection.

        Raises:
            Error: If an error occurred while accepting the connection.
        """
        return TCPConnection(self.socket.accept())

    fn close(mut self) raises -> None:
        """Closes the underlying file descriptor.

        Raises:
            Error: If an error occurred while closing the file descriptor.
        """
        return self.socket.close()


alias TCP_NETWORK_TYPES = InlineList[String, 3]("tcp", "tcp4", "tcp6")
"""The supported TCP network types."""


fn dial_tcp(network: String, remote_address: TCPAddr) raises -> TCPConnection:
    """Connects to the address on the named network.

    The network must be "tcp", "tcp4", or "tcp6".
    Args:
        network: The network type.
        remote_address: The remote address to connect to.

    Returns:
        The TCP connection.

    Raises:
        Error: If the network type is not supported or failed to connect to the remote address.
    """
    # TODO: Add conversion of domain name to ip address
    if network not in TCP_NETWORK_TYPES:
        raise Error("unsupported network type: " + network)

    socket = Socket()
    socket.connect(remote_address.ip, remote_address.port)
    return TCPConnection(socket^)


fn dial_tcp(network: String, remote_address: String) raises -> TCPConnection:
    """Connects to the address on the named network.

    The network must be "tcp", "tcp4", or "tcp6".
    Args:
        network: The network type.
        remote_address: The remote address to connect to. (The format is "host:port").

    Returns:
        The TCP connection.

    Raises:
        Error: If the network type is not supported or failed to connect to the remote address.
    """
    return dial_tcp(network, TCPAddr(split_host_port(remote_address)))


fn dial_tcp(network: String, host: String, port: Int) raises -> TCPConnection:
    """Connects to the address on the named network.

    The network must be "tcp", "tcp4", or "tcp6".
    Args:
        network: The network type.
        host: The remote address to connect to in ipv4 format.
        port: The remote port.

    Returns:
        The TCP connection.

    Raises:
        Error: If the network type is not supported or failed to connect to the remote address.
    """
    return dial_tcp(network, TCPAddr(host, port))
