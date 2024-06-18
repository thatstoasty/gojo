from gojo.net import Socket, UDPAddr, get_ip_address, listen_udp
from gojo.syscall import SocketOptions, ProtocolFamily


fn test_listener() raises:
    var listener = listen_udp("udp", UDPAddr("0.0.0.0", 8081))
    var result = listener.write(String("Hello, world!").as_bytes())
    if result[1]:
        raise result[1]

    print(result[0])
    var dest = List[UInt8](capacity=16)
    result = listener.read(dest)
    if result[1]:
        raise result[1]

    print(result[0])
    print(String(dest))
    _ = listener.close()
    # while True:
    #     var conn = listener.accept()
    #     var err = conn.close()
    #     if err:
    #         raise err


fn main() raises:
    # test_stuff()
    test_listener()
    # test_dial()
