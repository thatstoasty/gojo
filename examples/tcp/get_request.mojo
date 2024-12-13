from gojo.net import TCPAddr, get_ip_address, dial_tcp
from gojo.syscall import ProtocolFamily
import gojo.io


fn main() raises:
    # Connect to example.com on port 80 and send a GET request
    var connection = dial_tcp("tcp", TCPAddr(get_ip_address("www.example.com"), 80))
    connection.write("GET / HTTP/1.1\r\nHost: www.example.com\r\nConnection: close\r\n\r\n")

    # Read the response from the connection
    var response = List[UInt8, True](capacity=4096)
    try:
        bytes_read = connection.read(response)
    except e:
        if str(e) != str(io.EOF):
            raise e

    if bytes_read == 0:
        print("No bytes received from peer.")
        return

    response.append(0)
    print(String(response^))

    # Cleanup the connection
    connection.close()
