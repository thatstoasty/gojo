"""Adapted from go's net package

A good chunk of the leg work here came from the lightbug_http project! https://github.com/saviorand/lightbug_http/tree/main
"""

from .fd import FileDescriptor
from .socket import Socket
from .tcp import TCPConnection, TCPListener, listen_tcp, dial_tcp, TCPAddr
from .address import NetworkType, Addr
from .ip import get_ip_address, get_addr_info
from .dial import Dialer
from .net import Connection, Conn


# Time in nanoseconds
alias Duration = Int
alias DEFAULT_BUFFER_SIZE = 4096
alias DEFAULT_TCP_KEEP_ALIVE = Duration(15 * 1000 * 1000 * 1000)  # 15 seconds
