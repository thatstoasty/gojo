# from collections.optional import Optional
# from memory._arc import Arc
# from .request import Request
# from .header import Header
# from .status import StatusSwitchingProtocols
# from ..tcp import listen_tcp, TCPListener, TCPConnection
# from ...builtins import WrappedError, Result
# import ...io


# alias ErrServerClosed = "http: Server closed"


# trait ResponseWriter(Movable, Copyable, io.Writer):
#     # TODO: Temporary until traits support variables.
#     fn get_headers(self, key: String) -> Header:
#         """Returns the header map that will be sent by
#         [ResponseWriter.WriteHeader]. The [Header] map also is the mechanism with which
#         [Handler] implementations can set HTTP trailers.

#         Changing the header map after a call to [ResponseWriter.WriteHeader] (or
#         [ResponseWriter.Write]) has no effect unless the HTTP status code was of the
#         1xx class or the modified headers are trailers.

#         There are two ways to set Trailers. The preferred way is to
#         predeclare in the headers which trailers you will later
#         send by setting the "Trailer" header to the names of the
#         trailer keys which will come later. In this case, those
#         keys of the Header map are treated as if they were
#         trailers. See the example. The second way, for trailer
#         keys not known to the [Handler] until after the first [ResponseWriter.Write],
#         is to prefix the [Header] map keys with the [TrailerPrefix]
#         constant value.

#         To suppress automatic response headers (such as "Date"), set
#         their value to nil."""
#         ...

#     fn write(inout self, src: List[Int8]) -> Result[Int]:
#         """Writes the data to the connection as part of an HTTP reply.

#         If [ResponseWriter.WriteHeader] has not yet been called, Write calls
#         WriteHeader(http.StatusOK) before writing the data. If the Header
#         does not contain a Content-Type line, Write adds a Content-Type set
#         to the result of passing the initial 512 bytes of written data to
#         [DetectContentType]. Additionally, if the total size of all written
#         data is under a few KB and there are no Flush calls, the
#         Content-Length header is added automatically.

#         Depending on the HTTP protocol version and the client, calling
#         Write or WriteHeader may prevent future reads on the
#         Request.Body. For HTTP/1.x requests, handlers should read any
#         needed request body data before writing the response. Once the
#         headers have been flushed (due to either an explicit Flusher.Flush
#         call or writing enough data to trigger a flush), the request body
#         may be unavailable. For HTTP/2 requests, the Go HTTP server permits
#         handlers to continue to read the request body while concurrently
#         writing the response. However, such behavior may not be supported
#         by all HTTP/2 clients. Handlers should read before writing if
#         possible to maximize compatibility."""
#         ...

#     fn write_header(self, status_code: Int):
#         """Sends an HTTP response header with the provided
#         status code.

#         If WriteHeader is not called explicitly, the first call to Write
#         will trigger an implicit WriteHeader(http.StatusOK).
#         Thus explicit calls to WriteHeader are mainly used to
#         send error codes or 1xx informational responses.

#         The provided code must be a valid HTTP 1xx-5xx status code.
#         Any number of 1xx headers may be written, followed by at most
#         one 2xx-5xx header. 1xx headers are sent immediately, but 2xx-5xx
#         headers may be buffered. Use the Flusher interface to send
#         buffered data. The header map is cleared when 2xx-5xx headers are
#         sent, but not with 1xx headers.

#         The server will automatically send a 100 (Continue) header
#         on the first read from the request body if the request has
#         an "Expect: 100-continue" header."""
#         ...


# trait Handler(Movable, Copyable):
#     fn serve_http[W: ResponseWriter](self, writer: W, request: request.Request):
#         ...


# @value
# struct DefaultHandler(Handler):
#     fn serve_http[W: ResponseWriter](self, writer: W, request: request.Request):
#         pass


# @value
# # TODO: Implement
# struct ServerResponse(ResponseWriter):
#     """Represents the server side of an HTTP response."""

#     var _connection: Arc[TCPConnection]
#     var status_code: Int
#     var headers: Header
#     var body: List[Int8]
#     var bytes_written: Int64 # number of bytes written in body
#     var content_length: Int64 # explicitly-declared Content-Length; or -1
#     var status: Int # status code passed to WriteHeader
#     # var request: Reference[Request, ]

#     fn __init__(
#         inout self,
#         _connection: Arc[TCPConnection],
#         status_code: Int = 0,
#         headers: Header = Header(),
#         body: List[Int8] = List[Int8](),
#         bytes_written: Int64 = 0,
#         content_length: Int64 = 0,
#         status: Int = 0,
#     ):
#         self._connection = _connection
#         self.status_code = status_code
#         self.headers = headers
#         self.body = body
#         self.bytes_written = bytes_written
#         self.content_length = content_length
#         self.status = status

#     fn get_headers(self, key: String) -> Header:
#         # if self.wrote_header and not self.cw.wrote_header:
#         #     # Accessing the header between logically writing it
#         #     # and physically writing it means we need to allocate
#         #     # a clone to snapshot the logically written state.
#         #     w.cw.header = w.handlerHeader.Clone()
#         # w.calledHeader = true
#         return self.headers

#     fn write(inout self, src: List[Int8]) -> Result[Int]:
#         return 0

#     fn write_header(self, status_code: Int):
#         # Handle informational headers.
#         #
#         # We shouldn't send any further headers after 101 Switching Protocols,
#         # so it takes the non-informational path.
#         if status_code >= 100 and status_code <= 199 and status_code != StatusSwitchingProtocols:
#             # Prevent a potential race with an automatically-sent 100 Continue triggered by Request.Body.Read()
#             if status_code == 100 and self.canWriteContinue.Load():
#                 self.writeContinueMu.Lock()
#                 self.canWriteContinue.Store(false)
#                 self.writeContinueMu.Unlock()

#             writeStatusLine(self.conn.bufw, self.req.ProtoAtLeast(1, 1), code, self.statusBuf[:])

#             # Per RFC 8297 we must not clear the current header map
#             self.handlerHeader.WriteSubset(self.conn.bufw, excludedHeadersNoBody)
#             self.conn.bufw.Write(crlf)
#             self.conn.bufw.Flush()

#             return

#         self.wroteHeader = true
#         self.status = status_code

#         if self.calledHeader and self.cw.header == nil:
#             self.cw.header = self.handlerHeader.Clone()

#         if cl = self.handlerHeader.get("Content-Length"); cl != "":
#             v, err = strconv.ParseInt(cl, 10, 64)
#             if err == nil and v >= 0:
#                 self.contentLength = v
#                 else:
#                 self.conn.server.logf("http: invalid Content-Length of %q", cl)
#                 self.handlerHeader.Del("Content-Length")


# struct Server[H: Handler]():
#     """A Server defines parameters for running an HTTP server."""

#     # # Addr optionally specifies the TCP address for the server to listen on,
#     # # in the form "host:port". If empty, ":http" (port 80) is used.
#     # # The service names are defined in RFC 6335 and assigned by IANA.
#     # # See net.Dial for details of the address format.
#     var address: String
#     var handler: H  # handler to invoke, http.DefaultServeMux if nil

#     # # MaxHeaderBytes controls the maximum number of bytes the
#     # # server will read parsing the request header's keys and
#     # # values, including the request line. It does not limit the
#     # # size of the request body.
#     # # If zero, DefaultMaxHeaderBytes is used.
#     # var MaxHeaderBytes: Int

#     var is_shutting_down: Bool

#     fn __init__(inout self, address: String, handler: H):
#         self.address = address
#         self.handler = handler
#         # self.MaxHeaderBytes = 0
#         self.is_shutting_down = False

#     fn serve(self, listener: TCPListener) raises -> Optional[WrappedError]:
#         """Accepts incoming connections on the Listener l, creating a
#         new service goroutine for each. The service goroutines read requests and
#         then call srv.Handler to reply to them.

#         HTTP/2 support is only enabled if the Listener returns [*tls.Conn]
#         connections and they were configured with "h2" in the TLS
#         Config.NextProtos.

#         Serve always returns a non-nil error and closes l.
#         After [Server.Shutdown] or [Server.Close], the returned error is [ErrServerClosed].
#         """
#         while True:
#             var conn = listener.accept()
#             self.handler.serve_http(Response(TCPConnection(conn)), Request())
#             var err = conn.close()
#             if err:
#                 raise err.value().error

#     fn listen_and_serve(self) raises -> Optional[WrappedError]:
#         """Listens on the TCP network address srv.Addr and then
#         calls [Serve] to handle requests on incoming connections.
#         Accepted connections are configured to enable TCP keep-alives.

#         If srv.Addr is blank, ":http" is used.

#         ListenAndServe always returns a non-nil error. After [Server.Shutdown] or [Server.Close],
#         the returned error is [ErrServerClosed].
#         """

#         if self.is_shutting_down:
#             return WrappedError(ErrServerClosed)

#         var addr = self.address
#         if addr == "":
#             addr = ":http"

#         var listener = listen_tcp("tcp", addr)

#         return self.serve(listener)


# fn listen_and_serve():
#     pass
