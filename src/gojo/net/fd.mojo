from utils import Span
from os import abort
from sys import external_call
from memory import UnsafePointer
import ..io
from ..syscall import (
    recv,
    send,
    close,
)


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
            try:
                self.close()
            except e:
                print(e)

    fn close(inout self) raises -> None:
        """Mark the file descriptor as closed."""
        if close(self.fd) == -1:
            raise Error("FileDescriptor.close: Failed to close socket.")

        self.is_closed = True

    fn _read(inout self, dest: UnsafePointer[Byte], capacity: Int) raises -> Int:
        """Receive data from the file descriptor and write it to the buffer provided.

        Args:
            dest: The destination buffer to write the data to.
            capacity: The capacity of the destination buffer.

        Returns:
            The number of bytes read, or an error if one occurred.
        """
        var bytes_received = recv(self.fd, dest, capacity, 0)
        if bytes_received == 0:
            raise Error(io.EOF)
        elif bytes_received == -1:
            raise Error("Failed to receive message from socket.")

        return bytes_received

    fn read(inout self, inout dest: List[Byte, True]) raises -> Int:
        """Receive data from the file descriptor and write it to the buffer provided.

        Args:
            dest: The destination buffer to write the data to.

        Returns:
            The number of bytes read, or an error if one occurred.
        """
        if dest.size == dest.capacity:
            raise Error("FileDescriptor.read: no space left in destination buffer.")

        bytes_read = self._read(dest.unsafe_ptr().offset(dest.size), dest.capacity - dest.size)
        dest.size += bytes_read
        return bytes_read

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
            abort("Failed to send message")

    fn write[*Ts: Writable](inout self, *args: *Ts) -> None:
        """Write data to the File Descriptor."""

        @parameter
        fn write_arg[T: Writable](arg: T):
            arg.write_to(self)

        args.each[write_arg]()
