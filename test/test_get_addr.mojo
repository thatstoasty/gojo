# from gojo.net import Socket, TCPAddr, get_ip_address, listen_tcp, dial_tcp
# from gojo.syscall import SocketOptions, ProtocolFamily


# def test_dial():
#     # Connect to example.com on port 80 and send a GET request
#     connection = dial_tcp("tcp", TCPAddr(get_ip_address("www.example.com"), 80))
#     bytes_written: Int = 0
#     err = Error()
#     bytes_written, err = connection.write(
#         String("GET / HTTP/1.1\r\nHost: www.example.com\r\nConnection: close\r\n\r\n").as_bytes()
#     )
#     if err:
#         raise err

#     if bytes_written == 0:
#         print("No bytes sent to peer.")
#         return

#     # Read the response from the connection
#     response = List[UInt8, True](capacity=4096)
#     bytes_read: Int = 0
#     bytes_read, err = connection.read(response)
#     if err:
#         raise err

#     if bytes_read == 0:
#         print("No bytes received from peer.")
#         return

#     print(String(response))

#     # Cleanup the connection
#     err = connection.close()
#     if err:
#         raise err


# def test_listener():
#     listener = listen_tcp("tcp", TCPAddr("0.0.0.0", 8081))
#     while True:
#         conn = listener.accept()
#         print("Accepted connection from", str(conn.remote_address()))
#         err = conn.close()
#         if err:
#             raise err


# def test_stuff():
#     # TODO: context manager not working yet
#     # with Socket() as socket:
#     #     socket.bind("0.0.0.0", 8080)

#     socket = Socket(protocol=ProtocolFamily.PF_UNIX)
#     socket.bind("0.0.0.0", 8080)
#     _ = socket.connect(get_ip_address("www.example.com"), 80)
#     print("File number", socket.file_no())
#     local = socket.get_sock_name()
#     remote = socket.get_peer_name()
#     print("Local address", str(local), str(socket.local_address))
#     print("Remote address", str(remote[0]), str(socket.remote_address))
#     socket.set_socket_option(SocketOptions.SO_REUSEADDR, 1)
#     print("REUSE_ADDR value", socket.get_socket_option(SocketOptions.SO_REUSEADDR))
#     # timeout = 30
#     # socket.set_timeout(timeout)
#     # print(socket.get_timeout())
#     socket.shutdown()
#     print("closing")
#     err = socket.close()
#     print("closed")
#     if err:
#         print("err returned")
#         raise err
#     # option_value = socket.get_sock_opt(SocketOptions.SO_REUSEADDR)
#     # print(option_value)
#     # socket.connect(self.ip, self.port)
#     # socket.send(message)
#     # response = socket.receive() # TODO: call receive until all data is fetched, receive should also just return bytes
#     # socket.shutdown()
#     # socket.close()


# def main():
#     test_dial()
#     # test_listener()
#     # test_stuff()
