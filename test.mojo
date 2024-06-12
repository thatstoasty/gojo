from gojo.net import get_ip_address
from gojo.net.async_socket import Socket
from gojo.syscall import ProtocolFamily


fn main() raises:
    var socket = Socket(protocol=ProtocolFamily.PF_UNIX)
    socket.bind("0.0.0.0", 8080)

    var i = 0
    while i < 5:
        var buf = List[UInt8](capacity=128)
        await socket.connect(get_ip_address("www.example.com"), 80)
        _ = await socket.write(
            String("GET / HTTP/1.1\r\nHost: www.example.com\r\nConnection: close\r\n\r\n").as_bytes_slice()
        )
        _ = await socket.read(buf)
        buf.append(0)
        var response = String(buf)
        i += 1

    print(response)
    socket.shutdown()
    var err = socket.close()
    if err:
        print("err returned")
        raise err
