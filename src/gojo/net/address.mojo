@value
struct NetworkType:
    var value: String

    alias empty = NetworkType("")
    alias tcp = NetworkType("tcp")
    alias tcp4 = NetworkType("tcp4")
    alias tcp6 = NetworkType("tcp6")
    alias udp = NetworkType("udp")
    alias udp4 = NetworkType("udp4")
    alias udp6 = NetworkType("udp6")
    alias ip = NetworkType("ip")
    alias ip4 = NetworkType("ip4")
    alias ip6 = NetworkType("ip6")
    alias unix = NetworkType("unix")


trait Addr(CollectionElement, Stringable):
    fn network(self) -> String:
        """Name of the network (for example, "tcp", "udp")."""
        ...


@value
struct BaseAddr:
    """Addr struct representing a TCP address.

    Args:
        ip: IP address.
        port: Port number.
        zone: IPv6 addressing zone.
    """

    var ip: String
    var port: Int
    var zone: String  # IPv6 addressing zone

    fn __init__(inout self, ip: String = "", port: Int = 0, zone: String = ""):
        self.ip = ip
        self.port = port
        self.zone = zone

    fn __init__(inout self, other: TCPAddr):
        self.ip = other.ip
        self.port = other.port
        self.zone = other.zone

    fn __init__(inout self, other: UDPAddr):
        self.ip = other.ip
        self.port = other.port
        self.zone = other.zone

    fn __str__(self) -> String:
        if self.zone != "":
            return join_host_port(self.ip + "%" + self.zone, str(self.port))
        return join_host_port(self.ip, str(self.port))


fn resolve_internet_addr(network: String, address: String) raises -> TCPAddr:
    """Resolve an address to a TCPAddr.

    Args:
        network: The network type.
        address: The address to resolve.

    Returns:
        A TCPAddr struct representing the resolved address.
    """
    var host: String = ""
    var port: String = ""
    var portnum: Int = 0
    if (
        network == NetworkType.tcp.value
        or network == NetworkType.tcp4.value
        or network == NetworkType.tcp6.value
        or network == NetworkType.udp.value
        or network == NetworkType.udp4.value
        or network == NetworkType.udp6.value
    ):
        if address != "":
            var result = split_host_port(address)

            host = result.host
            port = str(result.port)
            portnum = result.port
    elif network == NetworkType.ip.value or network == NetworkType.ip4.value or network == NetworkType.ip6.value:
        if address != "":
            host = address
    elif network == NetworkType.unix.value:
        raise Error("Unix addresses not supported yet")
    else:
        raise Error("unsupported network type: " + network)
    return TCPAddr(host, portnum)


alias MISSING_PORT_ERROR = "missing port in address"
alias TOO_MANY_COLONS_ERROR = "too many colons in address"


@value
struct HostPort(Stringable):
    var host: String
    var port: Int

    fn __init__(inout self, host: String = "", port: Int = 0):
        self.host = host
        self.port = port

    fn __str__(self) -> String:
        return self.host + ":" + str(self.port)


fn join_host_port(host: String, port: String) -> String:
    if host.find(":") != -1:  # must be IPv6 literal
        return "[" + host + "]:" + port
    return host + ":" + port


fn split_host_port(hostport: String) raises -> HostPort:
    var host: String = ""
    var port: String = ""
    var colon_index = hostport.rfind(":")
    var j: Int = 0
    var k: Int = 0

    if colon_index == -1:
        raise MISSING_PORT_ERROR
    if hostport[0] == "[":
        var end_bracket_index = hostport.find("]")
        if end_bracket_index == -1:
            raise Error("missing ']' in address")
        if end_bracket_index + 1 == len(hostport):
            raise MISSING_PORT_ERROR
        elif end_bracket_index + 1 == colon_index:
            host = hostport[1:end_bracket_index]
            j = 1
            k = end_bracket_index + 1
        else:
            if hostport[end_bracket_index + 1] == ":":
                raise TOO_MANY_COLONS_ERROR
            else:
                raise MISSING_PORT_ERROR
    else:
        host = hostport[:colon_index]
        if host.find(":") != -1:
            raise TOO_MANY_COLONS_ERROR
    if hostport[j:].find("[") != -1:
        raise Error("unexpected '[' in address")
    if hostport[k:].find("]") != -1:
        raise Error("unexpected ']' in address")
    port = hostport[colon_index + 1 :]

    if port == "":
        raise MISSING_PORT_ERROR
    if host == "":
        raise Error("missing host")

    try:
        return HostPort(host, atol(port))
    except e:
        raise e
