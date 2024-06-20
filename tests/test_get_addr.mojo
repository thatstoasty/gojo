from gojo.net import Socket, TCPAddr, get_ip_address, listen_tcp, dial_tcp
from gojo.syscall import SocketOptions, ProtocolFamily


fn test_dial() raises:
    # Connect to example.com on port 80 and send a GET request
    var connection = dial_tcp("tcp", TCPAddr(get_ip_address("www.example.com"), 80))
    var bytes_written: Int = 0
    var err = Error()
    bytes_written, err = connection.write(
        String("GET / HTTP/1.1\r\nHost: www.example.com\r\nConnection: close\r\n\r\n").as_bytes_slice()
    )
    if err:
        raise err

    if bytes_written == 0:
        print("No bytes sent to peer.")
        return

    # Read the response from the connection
    var response = List[UInt8](capacity=4096)
    var bytes_read: Int = 0
    bytes_read, err = connection.read(response)
    if err:
        raise err

    if bytes_read == 0:
        print("No bytes received from peer.")
        return

    print(String(response))

    # Cleanup the connection
    err = connection.close()
    if err:
        raise err


fn test_listener() raises:
    var listener = listen_tcp("tcp", TCPAddr("0.0.0.0", 8081))
    while True:
        var conn = listener.accept()
        print("Accepted connection from", conn.remote_address())
        var err = conn.close()
        if err:
            raise err


# fn test_stuff() raises:
#     # TODO: context manager not working yet
#     # with Socket() as socket:
#     #     socket.bind("0.0.0.0", 8080)

#     var socket = Socket(protocol=ProtocolFamily.PF_UNIX)
#     socket.bind("0.0.0.0", 8080)
#     socket.connect(get_ip_address("www.example.com"), 80)
#     print("File number", socket.file_no())
#     var local = socket.get_sock_name()
#     var remote = socket.get_peer_name()
#     print("Local address", str(local), socket.local_address)
#     print("Remote address", str(remote), socket.remote_address)
#     socket.set_socket_option(SocketOptions.SO_REUSEADDR, 1)
#     print("REUSE_ADDR value", socket.get_socket_option(SocketOptions.SO_REUSEADDR))
#     var timeout = 30
#     # socket.set_timeout(timeout)
#     # print(socket.get_timeout())
#     socket.shutdown()
#     print("closing")
#     var err = socket.close()
#     print("closed")
#     if err:
#         print("err returned")
#         raise err
#     # var option_value = socket.get_sock_opt(SocketOptions.SO_REUSEADDR)
#     # print(option_value)
#     # socket.connect(self.ip, self.port)
#     # socket.send(message)
#     # var response = socket.receive() # TODO: call receive until all data is fetched, receive should also just return bytes
#     # socket.shutdown()
#     # socket.close()


fn main() raises:
    # test_stuff()
    # test_listener()
    test_dial()
