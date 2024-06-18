from collections.optional import Optional
import ...io
from .header import Header, has_token
from .response import Response


fn new_response_transfer_write[
    RWC: io.ReadWriteCloser
](response: Arc[Response[RWC]]) raises -> Arc[TransferWriter[io.Reader, io.Closer]]:
    return TransferWriter[io.Reader, io.Closer](TransferWriter[io.Reader, io.Closer](True, "", nil, nil, False))


struct TransferWriter[R: io.Reader, C: io.Closer]():
    """Inspects the fields of a user-supplied Request or Response,
    sanitizes them without changing the user object and provides methods for
    writing the respective header, body and trailer in wire format."""

    var method: String
    var body: R
    var body_closer: C
    var response_to_head: Bool
    var content_length: Int64  # -1 means unknown, 0 means exactly none
    var close: Bool
    # var transfer_encoding: List[String]
    var header: Header
    # var trailer: Header
    var is_response: Bool
    var body_read_error: Error  #  any non-EOF error from reading Body

    var flush_headers: Bool  # flush headers to network before body
    # var byte_read_ch   chan readResult  non-nil if probeRequestBody called

    fn __init__(
        inout self, is_response: Bool, method: String, owned body: R, owned body_closer: C, response_to_head: Bool
    ):
        self.is_response = is_response
        self.method = method
        self.body = body^
        self.body_closer = body_closer^
        self.response_to_head = response_to_head
        self.header = Header()
        # self.trailer = Header()
        # self.transfer_encoding = []
        self.content_length = -1
        self.close = False
        self.flush_headers = False
        self.body_read_error = Error()
        # self.flush_headers = false

    fn __moveinit__(inout self, owned other: TransferWriter[R, C]):
        self.method = other.method^
        self.body = other.body^
        self.body_closer = other.body_closer^
        self.response_to_head = other.response_to_head
        self.content_length = other.content_length
        self.close = other.close
        self.header = other.header^
        # self.trailer = other.trailer
        # self.transfer_encoding = other.transfer_encoding
        self.is_response = other.is_response
        self.body_read_error = other.body_read_error^
        self.flush_headers = other.flush_headers
        # self.byte_read_ch = other.byte_read_ch

    fn write_header[W: io.Writer](inout self, inout writer: W) -> Error:
        var err = Error()
        if self.close:
            var contains_token = False
            try:
                contains_token = has_token(self.header.get("Connection"), "close")
            except e:
                return e

            if not contains_token:
                _, err = writer.write(String("Connection: close\r\n").as_bytes())
                if err:
                    return err

        # Write Content-Length and/or Transfer-Encoding whose values are a
        # function of the sanitized field triple (Body, ContentLength,
        # TransferEncoding)
        # Just using true instead of should_send_content_length field
        # if self.should_send_content_length():
        @parameter
        if True:
            _, err = writer.write(String("Content-Length: ").as_bytes())
            if err:
                return err

            _, err = writer.write(str(self.content_length).as_bytes())
            if err:
                return err

        return err

    # fn write_body[W: io.Writer](inout self, writer: W) -> Error:
    #     var ncopy: Int64
    #     var closed = False
    #     defer fn():
    #         if closed or self.BodyCloser == nil:
    #             return

    #         if closeErr := self.BodyCloser.Close(); closeErr != nil and err == nil:
    #             err = closeErr

    #     ()

    #     # Write body. We "unwrap" the body first if it was wrapped in a
    #     # nopCloser or readTrackingBody. This is to ensure that we can take advantage of
    #     # OS-level optimizations in the event that the body is an
    #     # *os.File.
    #     if self.Body != nil:
    #         var body = self.unwrapBody()
    #         if chunked(self.TransferEncoding):
    #             if bw, ok := w.(*bufio.Writer); ok and not self.IsResponse:
    #                 w = &internal.FlushAfterChunkWriter{Writer: bw

    #             cw := internal.NewChunkedWriter(w)
    #             _, err = self.doBodyCopy(cw, body)
    #             if err == nil:
    #                 err = cw.Close()

    #          else if self.ContentLength == -1:
    #             dst := w
    #             if self.Method == "CONNECT":
    #                 dst = bufioFlushWriter{dst

    #             ncopy, err = self.doBodyCopy(dst, body)
    #          else:
    #             ncopy, err = self.doBodyCopy(w, io.LimitReader(body, self.ContentLength))
    #             if err != nil:
    #                 return err

    #             var nextra int64
    #             nextra, err = self.doBodyCopy(io.Discard, body)
    #             ncopy += nextra

    #         if err != nil:
    #             return err

    #     if self.BodyCloser != nil:
    #         closed = true
    #         if err := self.BodyCloser.Close(); err != nil:
    #             return err

    #     if not self.ResponseToHEAD and self.ContentLength != -1 and self.ContentLength != ncopy:
    #         return fmt.Errorf("http: ContentLength=%d with Body length %d",
    #             self.ContentLength, ncopy)

    #     if chunked(self.TransferEncoding):
    #         # Write Trailer header
    #         if self.Trailer != nil:
    #             if err := self.Trailer.Write(w); err != nil:
    #                 return err

    #         # Last chunk, empty trailer
    #         _, err = io.WriteString(w, "\r\n")

    #     return err
