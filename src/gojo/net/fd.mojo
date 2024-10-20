from utils import Span
import ..io
from ..syscall import (
    recv,
    send,
    close,
)
from sys import external_call
from memory import UnsafePointer

alias O_RDWR = 0o2


struct FileDescriptor(Writer, io.Reader, io.Closer):
    var fd: Int
    var is_closed: Bool

    fn __init__(inout self, fd: Int):
        self.fd = fd
        self.is_closed = False

    fn __moveinit__(inout self, owned existing: Self):
        self.fd = existing.fd
        self.is_closed = existing.is_closed

    fn __del__(owned self):
        if not self.is_closed:
            var err = self.close()
            if err:
                print(str(err))

    fn close(inout self) -> Error:
        """Mark the file descriptor as closed."""
        var close_status = close(self.fd)
        if close_status == -1:
            return Error("FileDescriptor.close: Failed to close socket")

        self.is_closed = True
        return Error()

    fn _read(inout self, inout dest: UnsafePointer[UInt8], capacity: Int) -> (Int, Error):
        """Receive data from the file descriptor and write it to the buffer provided.

        Args:
            dest: The destination buffer to write the data to.
            capacity: The capacity of the destination buffer.

        Returns:
            The number of bytes read, or an error if one occurred.
        """
        var bytes_received = recv(self.fd, dest, capacity, 0)
        if bytes_received == 0:
            return bytes_received, Error(io.EOF)

        if bytes_received == -1:
            return 0, Error("Failed to receive message from socket.")

        return bytes_received, Error()

    fn read(inout self, inout dest: List[UInt8, True]) -> (Int, Error):
        """Receive data from the file descriptor and write it to the buffer provided.

        Args:
            dest: The destination buffer to write the data to.

        Returns:
            The number of bytes read, or an error if one occurred.
        """
        if dest.size == dest.capacity:
            return 0, Error("net.FileDescriptor.read: no space left in destination buffer.")

        var dest_ptr = dest.unsafe_ptr().offset(dest.size)
        var bytes_read: Int
        var err: Error
        bytes_read, err = self._read(dest_ptr, dest.capacity - dest.size)
        dest.size += bytes_read

        return bytes_read, err

    @always_inline
    fn write_bytes(inout self, bytes: Span[Byte, _]) -> None:
        """
        Write a `Span[Byte]` to this `Writer`.
        Args:
            bytes: The string slice to write to this Writer. Must NOT be
              null-terminated.
        """
        if len(bytes) == 0:
            return

        var bytes_sent = send(self.fd, bytes.unsafe_ptr(), len(bytes), 0)
        if bytes_sent == -1:
            panic("Failed to send message")

    fn write[*Ts: Writable](inout self, *args: *Ts) -> None:
        """Write data to the File Descriptor."""

        @parameter
        fn write_arg[T: Writable](arg: T):
            arg.write_to(self)

        args.each[write_arg]()
