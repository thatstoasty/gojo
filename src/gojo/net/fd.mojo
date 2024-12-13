from memory import Span
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
    """A file descriptor."""

    var fd: Int
    """The file descriptor number."""
    var is_closed: Bool
    """Whether the file descriptor is closed."""

    fn __init__(out self, fd: Int):
        """Initialize the file descriptor.

        Args:
            fd: The file descriptor number.
        """
        self.fd = fd
        self.is_closed = False

    fn __moveinit__(out self, owned existing: Self):
        """Initialize the file descriptor by moving the data from an existing file descriptor.

        Args:
            existing: The existing file descriptor to move the data from.
        """
        self.fd = existing.fd
        self.is_closed = existing.is_closed

    fn __del__(owned self):
        """Close the file descriptor."""
        if not self.is_closed:
            try:
                self.close()
            except e:
                print(e)

    fn close(mut self) raises -> None:
        """Mark the file descriptor as closed.

        Raises:
            Error: If the file descriptor could not be closed.
        """
        if close(self.fd) == -1:
            raise Error("FileDescriptor.close: Failed to close socket.")

        self.is_closed = True

    fn _read(mut self, dest: UnsafePointer[Byte], capacity: Int) raises -> Int:
        """Receive data from the file descriptor and write it to the buffer provided.

        Args:
            dest: The destination buffer to write the data to.
            capacity: The capacity of the destination buffer.

        Returns:
            The number of bytes read, or an error if one occurred.

        Raises:
            Error: If an error occurred while reading data.
        """
        var bytes_received = recv(self.fd, dest, capacity, 0)
        if bytes_received == 0:
            raise Error(io.EOF)
        elif bytes_received == -1:
            raise Error("Failed to receive message from socket.")

        return bytes_received

    fn read(mut self, mut dest: List[Byte, True]) raises -> Int:
        """Receive data from the file descriptor and write it to the buffer provided.

        Args:
            dest: The destination buffer to write the data to.

        Returns:
            The number of bytes read, or an error if one occurred.

        Raises:
            Error: If an error occurred while reading data.
        """
        if dest.size == dest.capacity:
            raise Error("FileDescriptor.read: no space left in destination buffer.")

        bytes_read = self._read(dest.unsafe_ptr().offset(len(dest)), dest.capacity - dest.size)
        dest.size += bytes_read
        return bytes_read

    @always_inline
    fn write_bytes(mut self, bytes: Span[Byte, _]) -> None:
        """Write a `Span[Byte]` to this `Writer`.

        Args:
            bytes: The string slice to write to this Writer. Must NOT be null-terminated.
        """
        if len(bytes) == 0:
            return

        var bytes_sent = send(self.fd, bytes.unsafe_ptr(), len(bytes), 0)
        if bytes_sent == -1:
            abort("Failed to send message")

    fn write[*Ts: Writable](mut self, *args: *Ts) -> None:
        """Write data to the File Descriptor.

        Parameters:
            Ts: The types of the arguments to write.

        Args:
            args: The arguments to write.
        """

        @parameter
        fn write_arg[T: Writable](arg: T):
            arg.write_to(self)

        args.each[write_arg]()
