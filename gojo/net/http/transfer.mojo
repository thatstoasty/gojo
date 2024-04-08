from collections.optional import Optional
import ...io
from ...builtins import Result, WrappedError
from .header import Header


struct TransferWriter[R: io.Reader, C: io.Closer]():
    """Inspects the fields of a user-supplied Request or Response,
    sanitizes them without changing the user object and provides methods for
    writing the respective header, body and trailer in wire format."""
    var method: String
    var body: R
    var body_closer: C
    var response_to_head: Bool
    var content_length: Int64  #-1 means unknown, 0 means exactly none
    var close: Bool
    # var transfer_encoding: List[String]
    var header: Header
    # var trailer: Header
    var is_response: Bool
    var body_read_error: Optional[WrappedError] #  any non-EOF error from reading Body

    var flush_headers: Bool # flush headers to network before body
    # var byte_read_ch   chan readResult  non-nil if probeRequestBody called

    fn __init__(inout self, is_response: Bool, method: String, body: R, body_closer: C, response_to_head: Bool):
        self.is_response = is_response
        self.method = method
        self.body = body ^
        self.body_closer = body_closer ^
        self.response_to_head = response_to_head
        self.header = Header()
        # self.trailer = Header()
        # self.transfer_encoding = []
        self.content_length = -1
        self.close = False
        self.flush_headers = False
        self.body_read_error = None
        # self.flush_headers = false
