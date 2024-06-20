import ..io
from ..syscall import (
    recv,
    send,
    close,
    FileDescriptorBase,
)

alias O_RDWR = 0o2


struct FileDescriptor(FileDescriptorBase):
    var fd: Int
    var is_closed: Bool

    @always_inline
    fn __init__(inout self, fd: Int):
        self.fd = fd
        self.is_closed = False

    @always_inline
    fn __moveinit__(inout self, owned existing: Self):
        self.fd = existing.fd
        self.is_closed = existing.is_closed

    @always_inline
    fn __del__(owned self):
        if not self.is_closed:
            var err = self.close()
            if err:
                print(str(err))

    @always_inline
    fn close(inout self) -> Error:
        """Mark the file descriptor as closed."""
        var close_status = close(self.fd)
        if close_status == -1:
            return Error("FileDescriptor.close: Failed to close socket")

        self.is_closed = True
        return Error()

    @always_inline
    fn _read(inout self, inout dest: Span[UInt8, True], capacity: Int) -> (Int, Error):
        """Receive data from the file descriptor and write it to the buffer provided."""
        var bytes_received = recv(
            self.fd,
            dest.unsafe_ptr() + len(dest),
            capacity - len(dest),
            0,
        )
        if bytes_received == 0:
            return bytes_received, io.EOF

        if bytes_received == -1:
            return 0, Error("Failed to receive message from socket.")
        dest._len += bytes_received

        return bytes_received, Error()

    @always_inline
    fn read(inout self, inout dest: List[UInt8]) -> (Int, Error):
        """Receive data from the file descriptor and write it to the buffer provided."""
        var span = Span(dest)

        var bytes_read: Int
        var err: Error
        bytes_read, err = self._read(span, dest.capacity)
        dest.size += bytes_read

        return bytes_read, err

    @always_inline
    fn write(inout self, src: List[UInt8]) -> (Int, Error):
        """Write data from the buffer to the file descriptor."""
        return self._write(Span(src))

    @always_inline
    fn _write(inout self, src: Span[UInt8]) -> (Int, Error):
        """Write data from the buffer to the file descriptor."""
        var bytes_sent = send(self.fd, src.unsafe_ptr(), len(src), 0)
        if bytes_sent == -1:
            return 0, Error("Failed to send message")

        return bytes_sent, Error()
