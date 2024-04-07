from collections.optional import Optional
from memory._arc import Arc
from .request import Request
from .header import Header
from ..tcp import listen_tcp, TCPListener, TCPConnection
from ...builtins import WrappedError, Result
import ...io


alias ErrServerClosed = "http: Server closed"


trait ResponseWriter(Movable, Copyable, io.Writer):
    # TODO: Temporary until traits support variables.
    fn get_headers(self, key: String) -> Header:
        """Returns the header map that will be sent by
        [ResponseWriter.WriteHeader]. The [Header] map also is the mechanism with which
        [Handler] implementations can set HTTP trailers.

        Changing the header map after a call to [ResponseWriter.WriteHeader] (or
        [ResponseWriter.Write]) has no effect unless the HTTP status code was of the
        1xx class or the modified headers are trailers.

        There are two ways to set Trailers. The preferred way is to
        predeclare in the headers which trailers you will later
        send by setting the "Trailer" header to the names of the
        trailer keys which will come later. In this case, those
        keys of the Header map are treated as if they were
        trailers. See the example. The second way, for trailer
        keys not known to the [Handler] until after the first [ResponseWriter.Write],
        is to prefix the [Header] map keys with the [TrailerPrefix]
        constant value.

        To suppress automatic response headers (such as "Date"), set
        their value to nil."""
        ...

    fn write(inout self, src: List[Int8]) -> Result[Int]:
        """Writes the data to the connection as part of an HTTP reply.

        If [ResponseWriter.WriteHeader] has not yet been called, Write calls
        WriteHeader(http.StatusOK) before writing the data. If the Header
        does not contain a Content-Type line, Write adds a Content-Type set
        to the result of passing the initial 512 bytes of written data to
        [DetectContentType]. Additionally, if the total size of all written
        data is under a few KB and there are no Flush calls, the
        Content-Length header is added automatically.

        Depending on the HTTP protocol version and the client, calling
        Write or WriteHeader may prevent future reads on the
        Request.Body. For HTTP/1.x requests, handlers should read any
        needed request body data before writing the response. Once the
        headers have been flushed (due to either an explicit Flusher.Flush
        call or writing enough data to trigger a flush), the request body
        may be unavailable. For HTTP/2 requests, the Go HTTP server permits
        handlers to continue to read the request body while concurrently
        writing the response. However, such behavior may not be supported
        by all HTTP/2 clients. Handlers should read before writing if
        possible to maximize compatibility."""
        ...

    fn write_header(self, status_code: Int):
        """Sends an HTTP response header with the provided
        status code.

        If WriteHeader is not called explicitly, the first call to Write
        will trigger an implicit WriteHeader(http.StatusOK).
        Thus explicit calls to WriteHeader are mainly used to
        send error codes or 1xx informational responses.

        The provided code must be a valid HTTP 1xx-5xx status code.
        Any number of 1xx headers may be written, followed by at most
        one 2xx-5xx header. 1xx headers are sent immediately, but 2xx-5xx
        headers may be buffered. Use the Flusher interface to send
        buffered data. The header map is cleared when 2xx-5xx headers are
        sent, but not with 1xx headers.

        The server will automatically send a 100 (Continue) header
        on the first read from the request body if the request has
        an "Expect: 100-continue" header."""
        ...


trait Handler(Movable, Copyable):
    fn serve_http[W: ResponseWriter](self, writer: W, request: request.Request):
        ...


@value
struct DefaultHandler(Handler):
    fn serve_http[W: ResponseWriter](self, writer: W, request: request.Request):
        pass


@value
# TODO: Implement
struct Response(ResponseWriter):
    """Represents the server side of a response."""

    var _connection: Arc[TCPConnection]
    var status_code: Int
    var headers: Header
    var body: List[Int8]
    # var request: Arc[Request]

    fn __init__(
        inout self,
        _connection: Arc[TCPConnection],
        status_code: Int = 0,
        headers: Header = Header(),
        body: List[Int8] = List[Int8](),
    ):
        self._connection = _connection
        self.status_code = status_code
        self.headers = headers
        self.body = body

    fn get_headers(self, key: String) -> Header:
        return Header()

    fn write(inout self, src: List[Int8]) -> Result[Int]:
        return 0

    fn write_header(self, status_code: Int):
        pass


struct Server[H: Handler]():
    """A Server defines parameters for running an HTTP server."""

    # # Addr optionally specifies the TCP address for the server to listen on,
    # # in the form "host:port". If empty, ":http" (port 80) is used.
    # # The service names are defined in RFC 6335 and assigned by IANA.
    # # See net.Dial for details of the address format.
    var address: String
    var handler: H  # handler to invoke, http.DefaultServeMux if nil

    # # MaxHeaderBytes controls the maximum number of bytes the
    # # server will read parsing the request header's keys and
    # # values, including the request line. It does not limit the
    # # size of the request body.
    # # If zero, DefaultMaxHeaderBytes is used.
    # var MaxHeaderBytes: Int

    var is_shutting_down: Bool

    fn __init__(inout self, address: String, handler: H):
        self.address = address
        self.handler = handler
        # self.MaxHeaderBytes = 0
        self.is_shutting_down = False

    fn serve(self, listener: TCPListener) raises -> Optional[WrappedError]:
        """Accepts incoming connections on the Listener l, creating a
        new service goroutine for each. The service goroutines read requests and
        then call srv.Handler to reply to them.

        HTTP/2 support is only enabled if the Listener returns [*tls.Conn]
        connections and they were configured with "h2" in the TLS
        Config.NextProtos.

        Serve always returns a non-nil error and closes l.
        After [Server.Shutdown] or [Server.Close], the returned error is [ErrServerClosed].
        """
        while True:
            var conn = listener.accept()
            self.handler.serve_http(Response(TCPConnection(conn)), Request())
            var err = conn.close()
            if err:
                raise err.value().error

    fn listen_and_serve(self) raises -> Optional[WrappedError]:
        """Listens on the TCP network address srv.Addr and then
        calls [Serve] to handle requests on incoming connections.
        Accepted connections are configured to enable TCP keep-alives.

        If srv.Addr is blank, ":http" is used.

        ListenAndServe always returns a non-nil error. After [Server.Shutdown] or [Server.Close],
        the returned error is [ErrServerClosed].
        """

        if self.is_shutting_down:
            return WrappedError(ErrServerClosed)

        var addr = self.address
        if addr == "":
            addr = ":http"

        var listener = listen_tcp("tcp", addr)

        return self.serve(listener)


fn listen_and_serve():
    pass
