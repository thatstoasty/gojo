from utils import Span
from ..syscall import (
    socket,
    connect,
    recv,
    recvfrom,
    send,
    sendto,
    shutdown,
    inet_pton,
    inet_ntoa,
    inet_ntop,
    htons,
    ntohs,
    getaddrinfo,
    getaddrinfo_unix,
    gai_strerror,
    bind,
    listen,
    accept,
    setsockopt,
    getsockopt,
    getsockname,
    getpeername,
    close,
    sockaddr,
    sockaddr_in,
    addrinfo,
    addrinfo_unix,
    socklen_t,
    c_void,
    c_uint,
    c_char,
    c_int,
    AddressFamily,
    AddressInformation,
    SocketOptions,
    SocketType,
    SHUT_RDWR,
    SOL_SOCKET,
)
from .ip import (
    convert_binary_ip_to_string,
    build_sockaddr,
    build_sockaddr_in,
    convert_binary_port_to_int,
    convert_sockaddr_to_host_port,
)
from .fd import FileDescriptor
from .address import Addr, BaseAddr, HostPort
from sys import sizeof, external_call
from memory import Pointer, UnsafePointer


alias SocketClosedError = "Socket: Socket is already closed"


struct Socket(Writer, io.Reader, io.Closer):
    """Represents a network file descriptor. Wraps around a file descriptor and provides network functions.

    Args:
        local_address: The local address of the socket (local address if bound).
        remote_address: The remote address of the socket (peer's address if connected).
        address_family: The address family of the socket.
        socket_type: The socket type.
        protocol: The protocol.
    """

    var fd: FileDescriptor
    var address_family: Int
    var socket_type: Int32
    var protocol: Byte
    var local_address: BaseAddr
    var remote_address: BaseAddr
    var _closed: Bool
    var _is_connected: Bool

    fn __init__(
        inout self,
        local_address: BaseAddr = BaseAddr(),
        remote_address: BaseAddr = BaseAddr(),
        address_family: Int = AddressFamily.AF_INET,
        socket_type: Int32 = SocketType.SOCK_STREAM,
        protocol: Byte = 0,
    ) raises:
        """Create a new socket object.

        Args:
            local_address: The local address of the socket (local address if bound).
            remote_address: The remote address of the socket (peer's address if connected).
            address_family: The address family of the socket.
            socket_type: The socket type.
            protocol: The protocol.
        """
        self.address_family = address_family
        self.socket_type = socket_type
        self.protocol = protocol

        fd = socket(address_family, socket_type, 0)
        if fd == -1:
            raise Error("Socket creation error")
        self.fd = FileDescriptor(int(fd))
        self.local_address = local_address
        self.remote_address = remote_address
        self._closed = False
        self._is_connected = False

    fn __init__(
        inout self,
        fd: Int32,
        address_family: Int,
        socket_type: Int32,
        protocol: Byte,
        local_address: BaseAddr = BaseAddr(),
        remote_address: BaseAddr = BaseAddr(),
    ):
        """
        Create a new socket object when you already have a socket file descriptor. Typically through socket.accept().

        Args:
            fd: The file descriptor of the socket.
            address_family: The address family of the socket.
            socket_type: The socket type.
            protocol: The protocol.
            local_address: The local address of the socket (local address if bound).
            remote_address: The remote address of the socket (peer's address if connected).
        """
        self.fd = FileDescriptor(int(fd))
        self.address_family = address_family
        self.socket_type = socket_type
        self.protocol = protocol
        self.local_address = local_address
        self.remote_address = remote_address
        self._closed = False
        self._is_connected = True

    fn __moveinit__(inout self, owned existing: Self):
        self.fd = existing.fd^
        self.address_family = existing.address_family
        self.socket_type = existing.socket_type
        self.protocol = existing.protocol
        self.local_address = existing.local_address^
        self.remote_address = existing.remote_address^
        self._closed = existing._closed
        self._is_connected = existing._is_connected

    # fn __enter__(self) -> Self:
    #     return self

    # fn __exit__(inout self) raises:
    #     if self._is_connected:
    #         self.shutdown()
    #     if not self._closed:
    #         err = self.close()
    #         if err:
    #             raise err

    fn __del__(owned self):
        if self._is_connected:
            self.shutdown()

        if not self._closed:
            try:
                self.close()
            except e:
                print("Failed to close socket during deletion:", str(e))

    fn local_address_as_udp(self) -> UDPAddr:
        return UDPAddr(self.local_address)

    fn local_address_as_tcp(self) -> TCPAddr:
        return TCPAddr(self.local_address)

    fn remote_address_as_udp(self) -> UDPAddr:
        return UDPAddr(self.remote_address)

    fn remote_address_as_tcp(self) -> TCPAddr:
        return TCPAddr(self.remote_address)

    fn accept(self) raises -> Socket:
        """Accept a connection. The socket must be bound to an address and listening for connections.
        The return value is a connection where conn is a new socket object usable to send and receive data on the connection,
        and address is the address bound to the socket on the other end of the connection.
        """
        remote_address = sockaddr()
        new_fd = accept(
            self.fd.fd,
            Pointer.address_of(remote_address),
            Pointer.address_of(socklen_t(sizeof[socklen_t]())),
        )
        if new_fd == -1:
            _ = external_call["perror", c_void, UnsafePointer[Byte]](String("accept").unsafe_ptr())
            raise Error("Failed to accept connection")

        remote = convert_sockaddr_to_host_port(remote_address)
        _ = remote_address

        return Socket(
            new_fd,
            self.address_family,
            self.socket_type,
            self.protocol,
            self.local_address,
            BaseAddr(remote.host, remote.port),
        )

    fn listen(self, backlog: Int = 0) raises:
        """Enable a server to accept connections.

        Args:
            backlog: The maximum number of queued connections. Should be at least 0, and the maximum is system-dependent (usually 5).
        """
        queued = backlog
        if backlog < 0:
            queued = 0
        if listen(self.fd.fd, queued) == -1:
            raise Error("Failed to listen for connections")

    fn bind(inout self, address: String, port: Int) raises:
        """Bind the socket to address. The socket must not already be bound. (The format of address depends on the address family).

        When a socket is created with Socket(), it exists in a name
        space (address family) but has no address assigned to it.  bind()
        assigns the address specified by addr to the socket referred to
        by the file descriptor fd.  addrlen specifies the size, in
        bytes, of the address structure pointed to by addr.
        Traditionally, this operation is called 'assigning a name to a
        socket'.

        Args:
            address: String - The IP address to bind the socket to.
            port: The port number to bind the socket to.
        """
        local_address = build_sockaddr_in(address, port, self.address_family)
        if bind(self.fd.fd, Pointer.address_of(local_address), sizeof[sockaddr_in]()) == -1:
            _ = external_call["perror", c_void, UnsafePointer[Byte]](String("bind").unsafe_ptr())
            _ = shutdown(self.fd.fd, SHUT_RDWR)
            raise Error("Binding socket failed. Wait a few seconds and try again?")
        _ = local_address

        local = self.get_sock_name()
        self.local_address = BaseAddr(local.host, local.port)

    fn file_no(self) -> Int32:
        """Return the file descriptor of the socket."""
        return self.fd.fd

    fn get_sock_name(self) raises -> HostPort:
        """Return the address of the socket."""
        if self._closed:
            raise SocketClosedError

        # TODO: Add check to see if the socket is bound and error if not.
        local_address = sockaddr()
        local_address_size = socklen_t(sizeof[sockaddr]())
        status = getsockname(
            self.fd.fd,
            Pointer.address_of(local_address),
            Pointer.address_of(local_address_size),
        )
        if status == -1:
            _ = external_call["perror", c_void, UnsafePointer[Byte]]("getsockname".unsafe_ptr())
            raise Error("Socket.get_sock_name: Failed to get address of local socket.")
        addr_in = UnsafePointer.address_of(local_address).bitcast[sockaddr_in]().take_pointee()
        return HostPort(
            host=convert_binary_ip_to_string(addr_in.sin_addr.s_addr, AddressFamily.AF_INET, 16),
            port=convert_binary_port_to_int(addr_in.sin_port),
        )

    fn get_peer_name(self) raises -> HostPort:
        """Return the address of the peer connected to the socket."""
        if self._closed:
            raise SocketClosedError

        # TODO: Add check to see if the socket is bound and error if not.
        remote_address = sockaddr()
        remote_address_size = socklen_t(sizeof[sockaddr]())
        status = getpeername(
            self.fd.fd,
            Pointer.address_of(remote_address),
            Pointer.address_of(remote_address_size),
        )
        if status == -1:
            raise Error("Socket.get_peer_name: Failed to get address of remote socket.")

        return convert_sockaddr_to_host_port(remote_address)

    fn get_socket_option(self, option_name: Int) raises -> Int:
        """Return the value of the given socket option.

        Args:
            option_name: The socket option to get.
        """
        option_value_pointer = UnsafePointer[c_void].alloc(1)
        option_len = socklen_t(sizeof[c_void]())
        status = getsockopt(
            self.fd.fd,
            SOL_SOCKET,
            option_name,
            option_value_pointer,
            Pointer.address_of(option_len),
        )
        if status == -1:
            raise Error("Socket.get_sock_opt failed with status: " + str(status))

        return option_value_pointer.bitcast[Int]().take_pointee()

    fn set_socket_option(self, option_name: Int, owned option_value: Byte = 1) raises:
        """Return the value of the given socket option.

        Args:
            option_name: The socket option to set.
            option_value: The value to set the socket option to.
        """
        option_value_pointer = UnsafePointer[c_void].address_of(option_value)
        option_len = sizeof[socklen_t]()
        status = setsockopt(
            self.fd.fd,
            SOL_SOCKET,
            option_name,
            option_value_pointer,
            option_len,
        )
        if status == -1:
            raise Error("Socket.set_sock_opt failed with status: " + str(status))

    fn connect(inout self, address: String, port: Int) raises -> None:
        """Connect to a remote socket at address.

        Args:
            address: String - The IP address to connect to.
            port: The port number to connect to.
        """
        sa_in = build_sockaddr_in(address, port, self.address_family)
        if connect(self.fd.fd, Pointer.address_of(sa_in), sizeof[sockaddr_in]()) == -1:
            _ = external_call["perror", c_void, UnsafePointer[Byte]](String("connect").unsafe_ptr())
            self.shutdown()
            raise Error("Socket.connect: Failed to connect to the remote socket at: " + address + ":" + str(port))
        _ = sa_in

        remote = self.get_peer_name()
        self.remote_address = BaseAddr(remote.host, remote.port)

    @always_inline
    fn write_bytes(inout self, bytes: Span[Byte, _]) -> None:
        """
        Write a `Span[Byte]` to this `Writer`.
        Args:
            bytes: The string slice to write to this Writer. Must NOT be
              null-terminated.
        """
        self.fd.write_bytes(bytes)

    fn write[*Ts: Writable](inout self, *args: *Ts) -> None:
        """Write data to the File Descriptor."""

        @parameter
        fn write_arg[T: Writable](arg: T):
            arg.write_to(self)

        args.each[write_arg]()

    fn send_all(self, src: Span[Byte], max_attempts: Int = 3) raises -> None:
        """Send data to the socket. The socket must be connected to a remote socket.

        Args:
            src: The data to send.
            max_attempts: The maximum number of attempts to send the data.
        """
        bytes_to_send = len(src)
        total_bytes_sent = 0
        attempts = 0

        # Try to send all the data in the buffer. If it did not send all the data, keep trying but start from the offset of the last successful send.
        while total_bytes_sent < len(src):
            if attempts > max_attempts:
                raise Error("Failed to send message after " + str(max_attempts) + " attempts.")

            bytes_sent = send(
                self.fd.fd,
                src.unsafe_ptr() + total_bytes_sent,
                bytes_to_send - total_bytes_sent,
                0,
            )
            if bytes_sent == -1:
                raise Error("Failed to send message, wrote" + str(total_bytes_sent) + "bytes before failing.")
            total_bytes_sent += bytes_sent
            attempts += 1

    fn send_to(inout self, src: Span[Byte, _], address: String, port: Int) raises -> Int:
        """Send data to the a remote address by connecting to the remote socket before sending.
        The socket must be not already be connected to a remote socket.

        Args:
            src: The data to send.
            address: The IP address to connect to.
            port: The port number to connect to.
        """
        sa = build_sockaddr(address, port, self.address_family)
        bytes_sent = sendto(
            self.fd.fd,
            src.unsafe_ptr(),
            len(src),
            0,
            Pointer.address_of(sa),
            sizeof[sockaddr_in](),
        )

        if bytes_sent == -1:
            raise Error("Socket.send_to: Failed to send message to remote socket at: " + address + ":" + str(port))

        return bytes_sent

    fn receive(inout self, size: Int = io.BUFFER_SIZE) -> (List[Byte, True], Error):
        """Receive data from the socket into the buffer with capacity of `size` bytes.

        Args:
            size: The size of the buffer to receive data into.

        Returns:
            The buffer with the received data, and an error if one occurred.
        """
        buffer = UnsafePointer[Byte].alloc(size)
        bytes_received = recv(
            self.fd.fd,
            buffer,
            size,
            0,
        )
        if bytes_received == -1:
            return List[Byte, True](), Error("Socket.receive: Failed to receive message from socket.")

        bytes = List[Byte, True](unsafe_pointer=buffer, size=bytes_received, capacity=size)
        if bytes_received < bytes.capacity:
            return bytes, Error(io.EOF)

        return bytes, Error()

    fn _read(inout self, dest: UnsafePointer[Byte], capacity: Int) raises -> Int:
        """Receive data from the socket into the buffer dest.

        Args:
            dest: The buffer to read data into.
            capacity: The capacity of the buffer.

        Returns:
            The number of bytes read, and an error if one occurred.
        """
        return self.fd._read(dest, capacity)

    fn read(inout self, inout dest: List[Byte, True]) raises -> Int:
        """Receive data from the socket into the buffer dest. Equivalent to `recv_into()`.

        Args:
            dest: The buffer to read data into.

        Returns:
            The number of bytes read, and an error if one occurred.
        """
        return self.fd.read(dest)
        # if dest.size == dest.capacity:
        #     return 0, Error("net.socket.Socket.read: no space left in destination buffer.")

        # dest_ptr = dest.unsafe_ptr().offset(dest.size)
        # bytes_read: Int
        # err: Error
        # bytes_read, err = self._read(dest_ptr, dest.capacity - dest.size)
        # dest.size += bytes_read

        # print(bytes_read, str(err))
        # return bytes_read, err

    fn receive_from(inout self, size: Int = io.BUFFER_SIZE) raises -> (List[Byte, True], HostPort):
        """Receive data from the socket into the buffer dest.

        Args:
            size: The size of the buffer to receive data into.

        Returns:
            The number of bytes read, the remote address, and an error if one occurred.
        """
        remote_address = sockaddr()
        # remote_address_ptr = UnsafePointer[sockaddr].alloc(1)
        remote_address_ptr_size = socklen_t(sizeof[sockaddr]())
        buffer = UnsafePointer[Byte].alloc(size)
        bytes_received = recvfrom(
            self.fd.fd,
            buffer,
            size,
            0,
            Pointer.address_of(remote_address),
            Pointer.address_of(remote_address_ptr_size),
        )

        if bytes_received == 0:
            raise io.EOF
        elif bytes_received == -1:
            raise Error("Failed to read from socket, received a -1 response.")

        remote = convert_sockaddr_to_host_port(remote_address)
        return List[Byte, True](unsafe_pointer=buffer, size=bytes_received, capacity=size), remote

    fn receive_from_into(inout self, inout dest: List[Byte, True]) raises -> (Int, HostPort):
        """Receive data from the socket into the buffer dest."""
        remote_address = sockaddr()
        # remote_address_ptr = UnsafePointer[sockaddr].alloc(1)
        remote_address_ptr_size = socklen_t(sizeof[sockaddr]())
        bytes_read = recvfrom(
            self.fd.fd,
            dest.unsafe_ptr() + dest.size,
            dest.capacity - dest.size,
            0,
            Pointer.address_of(remote_address),
            Pointer.address_of(remote_address_ptr_size),
        )
        dest.size += bytes_read

        if bytes_read == 0:
            raise io.EOF
        elif bytes_read == -1:
            raise Error("Socket.receive_from_into: Failed to read from socket, received a -1 response.")

        return bytes_read, convert_sockaddr_to_host_port(remote_address)

    fn shutdown(self):
        _ = shutdown(self.fd.fd, SHUT_RDWR)

    fn close(inout self) raises -> None:
        """Mark the socket closed.
        Once that happens, all future operations on the socket object will fail.
        The remote end will receive no more data (after queued data is flushed).
        """
        self.shutdown()
        self.fd.close()

    # TODO: Trying to set timeout fails, but some other options don't?
    # fn get_timeout(self) raises -> Int:
    #     """Return the timeout value for the socket."""
    #     return self.get_socket_option(SocketOptions.SO_RCVTIMEO)

    # fn set_timeout(self, owned duration: Int) raises:
    #     """Set the timeout value for the socket.

    #     Args:
    #         duration: Seconds - The timeout duration in seconds.
    #     """
    #     self.set_socket_option(SocketOptions.SO_RCVTIMEO, duration)

    fn send_file(self, file: FileHandle) raises -> None:
        return self.send_all(file.read_bytes())
