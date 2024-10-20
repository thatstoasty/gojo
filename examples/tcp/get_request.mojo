from gojo.net import TCPAddr, get_ip_address, dial_tcp
from gojo.syscall import ProtocolFamily


fn main() raises:
    # Connect to example.com on port 80 and send a GET request
    var connection = dial_tcp("tcp", TCPAddr(get_ip_address("www.example.com"), 80))
    var bytes_written: Int = 0
    var err = Error()
    bytes_written, err = connection.write(
        String("GET / HTTP/1.1\r\nHost: www.example.com\r\nConnection: close\r\n\r\n").as_bytes()
    )
    if err:
        raise err

    if bytes_written == 0:
        print("No bytes sent to peer.")
        return

    # Read the response from the connection
    var response = List[UInt8, True](capacity=4096)
    var bytes_read: Int = 0
    bytes_read, err = connection.read(response)
    if err:
        raise err

    if bytes_read == 0:
        print("No bytes received from peer.")
        return

    response.append(0)
    print(String(response^))

    # Cleanup the connection
    err = connection.close()
    if err:
        raise err
