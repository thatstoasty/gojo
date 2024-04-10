from gojo.builtins import WrappedError


fn dummy() -> (Int, WrappedError):
    return (1, WrappedError("error"))


fn main():
    var result = dummy()
    result.get[1, WrappedError]()
