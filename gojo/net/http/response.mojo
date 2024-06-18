from collections.optional import Optional
import ...io
import ...bufio
from ...fmt import sprintf
from .header import Header
from .request import Request
from .status import status_text
from .transfer import TransferWriter


fn remove_prefix(input_string: String, prefix: String) -> String:
    if input_string.startswith(prefix):
        return input_string[len(prefix) :]
    return input_string


struct Response[RWC: io.ReadWriteCloser](Movable):
    """Response represents the response from an HTTP request.

    The [Client] and [Transport] return Responses from servers once
    the response headers have been received. The response body
    is streamed on demand as the body field is read."""

    var status: String  # e.g. "200 OK"
    var status_code: Int  # e.g. 200
    var proto: String  # e.g. "HTTP/1.0"
    var proto_major: Int  # e.g. 1
    var proto_minor: Int  # e.g. 0

    # Header maps header keys to values. If the response had multiple
    # headers with the same key, they may be concatenated, with comma
    # delimiters.  (RFC 7230, section 3.2.2 requires that multiple headers
    # be semantically equivalent to a comma-delimited sequence.) When
    # Header values are duplicated by other fields in this struct (e.g.,
    # content_length, TransferEncoding, Trailer), the field values are
    # authoritative.

    # Keys in the map are canonicalized (see CanonicalHeaderKey).
    var header: Header

    # body represents the response body.

    # The response body is streamed on demand as the body field
    # is read. If the network connection fails or the server
    # terminates the response, body.Read calls return an error.

    # The http Client and Transport guarantee that body is always
    # non-nil, even on responses without a body or responses with
    # a zero-length body. It is the caller's responsibility to
    # close body. The default HTTP client's Transport may not
    # reuse HTTP/1.x "keep-alive" TCP connections if the body is
    # not read to completion and closed.

    # The body is automatically dechunked if the server replied
    # with a "chunked" Transfer-Encoding.
    var body: RWC

    # content_length records the length of the associated content. The
    # value -1 indicates that the length is unknown. Unless Request.Method
    # is "HEAD", values >= 0 indicate that the given number of bytes may
    # be read from body.
    var content_length: Int64

    # Close records whether the header directed that the connection be
    # closed after reading body. The value is advice for clients: neither
    # ReadResponse nor Response.Write ever closes a connection.
    var close: Bool

    # Request is the request that was sent to obtain this Response.
    # Request's body is nil (having already been consumed).
    # This is only populated for Client requests.
    var request: Arc[Request]

    fn __init__(
        inout self,
        status: String,
        proto: String,
        proto_major: Int,
        proto_minor: Int,
        header: Header,
        owned body: RWC,
        content_length: Int64,
        close: Bool,
        request: Arc[Request],
    ):
        self.status = status
        self.proto = proto
        self.proto_major = proto_major
        self.proto_minor = proto_minor
        self.header = header
        self.body = body^
        self.content_length = content_length
        self.close = close
        self.request = request

    fn __moveinit__(inout self, owned other: Response[RWC]):
        self.status = other.status^
        self.status_code = other.status_code
        self.proto = other.proto^
        self.proto_major = other.proto_major
        self.proto_minor = other.proto_minor
        self.header = other.header^
        self.body = other.body^
        self.content_length = other.content_length
        self.close = other.close
        self.request = other.request^

    fn proto_at_least(self, major: Int, minor: Int) -> Bool:
        """Reports whether the HTTP protocol used
        in the response is at least major.minor.

        Args:
            major: Major version.
            minor: Minor version.
        """
        return self.proto_major > major or self.proto_major == major and self.proto_minor >= minor


#     fn write[W: io.Writer](inout self, inout writer: W) raises -> Error:
#         """Writes r to w in the HTTP/1.x server response format,
#         including the status line, headers, body, and optional trailer.

#         This method consults the following fields of the response r:

#             status_code
#             proto_major
#             proto_minor
#             Request.Method
#             TransferEncoding
#             Trailer
#             body
#             content_length
#             Header, values for non-canonical keys will have unpredictable behavior
#         The Response body is closed after it is sent.
#         """
#         # Status line
#         var text = self.status
#         if text == "":
#             text = status_text(self.status_code)
#             if text == "":
#                 text = "status code " + str(self.status_code)
#         else:
#             # Just to reduce stutter, if user set self.Status to "200 OK" and status_code to 200.
#             # Not important.
#             text = remove_prefix(text, str(self.status_code) + " ")

#         var first_line = sprintf(String("HTTP/%d.%d %d %s\r\n"), self.proto_major, self.proto_minor, self.status_code, text)
#         var bytes_written: Int
#         var err: Error
#         bytes_written, err = writer.write(first_line.as_bytes())
#         if err:
#             return err

#         if self.content_length == 0:
#             # Is it actually 0 length? Or just unknown?
#             var buf = List[UInt8](capacity=1)
#             var bytes_read: Int
#             bytes_read, err = self.body.read(buf)
#             if err:
#                 if str(err) != io.EOF:
#                     return err

#             if bytes_read == 0:
#                 # Reset it to a known zero reader, in case underlying one
#                 # is unhappy being read repeatedly.
#                 # self.body = NoBody
#                 pass
#             else:
#                 self.content_length = -1

#         # If we're sending a non-chunked HTTP/1.1 response without a
#         # content-length, the only way to do that is the old HTTP/1.0
#         # way, by noting the EOF with a connection close, so we need
#         # to set Close.
#         if self.content_length == -1 and not self.close and self.proto_at_least(1, 1):
#             self.close = True

#         # Process body,content_length,Close,Trailer
#         var tw = TransferWriter(self)
#         if err != nil:
#             return err

#         err = tw.writeHeader(w, nil)
#         if err != nil:
#             return err

#         # Rest of header
#         err = self.header.WriteSubset(w, respExcludeHeader)
#         if err != nil:
#             return err

#         # contentLengthAlreadySent may have been already sent for
#         # POST/PUT requests, even if zero length. See Issue 8180.
#         # contentLengthAlreadySent = tw.shouldSendContentLength()
#         if self.content_length == 0 and !chunked(self.TransferEncoding) and !contentLengthAlreadySent and bodyAllowedForStatus(self.status_code):
#             if _, err = io.WriteString(w, "Content-Length: 0\r\n"); err != nil:
#                 return err

#         # End-of-header
#         if _, err = io.WriteString(w, "\r\n"); err != nil:
#             return err

#         # Write body and trailer
#         err = tw.writeBody(w)
#         if err != nil:
#             return err

#         Success
#         return nil

#     fn close_body(inout self) -> Error:
#         return self.body.close()


# fn read_response[R: io.Reader](r: Arc[bufio.Reader[R]], req: Arc[Request]) -> Arc[Response]:
#     """Reads and returns an HTTP response from self.
#     The req parameter optionally specifies the [Request] that corresponds
#     to this [Response]. If nil, a GET request is assumed.
#     Clients must call resp.body.Close when finished reading resp.body.
#     After that call, clients can inspect resp.Trailer to find key/value
#     pairs included in the response trailer."""
#     tp = textproto.NewReader(r)
#     resp = &Response{
#         Request: req,

#     Parse the first line of the response.
#     line, err = tp.ReadLine()
#     if err != nil:
#         if err == io.EOF:
#             err = io.ErrUnexpectedEOF

#         return nil, err

#     proto, status, ok = strings.Cut(line, " ")
#     if not ok:
#         return nil, badStringError("malformed HTTP response", line)

#     resp.Proto = proto
#     resp.Status = strings.TrimLeft(status, " ")

#     statusCode, _, _ = strings.Cut(resp.Status, " ")
#     if len(statusCode) != 3:
#         return nil, badStringError("malformed HTTP status code", statusCode)

#     resp.status_code, err = strconv.Atoi(statusCode)
#     if err != nil or resp.status_code < 0:
#         return nil, badStringError("malformed HTTP status code", statusCode)

#     if resp.proto_major, resp.proto_minor, ok = ParseHTTPVersion(resp.Proto); !ok:
#         return nil, badStringError("malformed HTTP version", resp.Proto)


#     Parse the response headers.
#     mimeHeader, err = tp.ReadMIMEHeader()
#     if err != nil:
#         if err == io.EOF:
#             err = io.ErrUnexpectedEOF

#         return nil, err

#     resp.Header = Header(mimeHeader)

#     fixPragmaCacheControl(resp.Header)

#     err = readTransfer(resp, r)
#     if err != nil:
#         return nil, err


#     return resp, nil
