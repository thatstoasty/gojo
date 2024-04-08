from collections.optional import Optional
import ..io
from ..builtins import Byte, Result, WrappedError
from ..syscall.file import close
from ..syscall.types import c_char
from ..syscall.net import (
    recv,
    send,
    strlen,
)

alias O_RDWR = 0o2


trait FileDescriptorBase(io.Reader, io.Writer, io.Closer):
    ...


struct FileDescriptor(FileDescriptorBase):
    var fd: Int
    var is_closed: Bool

    # This takes ownership of a POSIX file descriptor.
    fn __moveinit__(inout self, owned existing: Self):
        self.fd = existing.fd
        self.is_closed = existing.is_closed

    fn __init__(inout self, fd: Int):
        self.fd = fd
        self.is_closed = False

    fn __del__(owned self):
        if not self.is_closed:
            var err = self.close()
            if err:
                print(err.value())

    fn close(inout self) -> Optional[WrappedError]:
        """Mark the file descriptor as closed."""
        var close_status = close(self.fd)
        if close_status == -1:
            return WrappedError("FileDescriptor.close: Failed to close socket")

        self.is_closed = True
        return None

    fn dup(self) -> Self:
        """Duplicate the file descriptor."""
        var new_fd = external_call["dup", Int, Int](self.fd)
        return Self(new_fd)

    # TODO: Need faster approach to copying data from the file descriptor to the buffer.
    fn read(inout self, inout dest: List[Byte]) -> Result[Int]:
        """Receive data from the file descriptor and write it to the buffer provided."""
        var ptr = Pointer[UInt8]().alloc(dest.capacity)
        var bytes_received = recv(self.fd, ptr, dest.capacity, 0)
        if bytes_received == -1:
            return Result(0, WrappedError("Failed to receive message from socket."))

        var int8_ptr = ptr.bitcast[Int8]()
        for i in range(bytes_received):
            dest.append(int8_ptr[i])

        if bytes_received < dest.capacity:
            return Result(bytes_received, WrappedError(io.EOF))

        return bytes_received

    fn write(inout self, src: List[Byte]) -> Result[Int]:
        """Write data from the buffer to the file descriptor."""
        var header_pointer = Pointer[Int8](src.data.value).bitcast[UInt8]()

        var bytes_sent = send(self.fd, header_pointer, strlen(header_pointer), 0)
        if bytes_sent == -1:
            return Result(0, WrappedError("Failed to send message"))

        return bytes_sent
