from collections.optional import Optional


@value
struct WrappedError(CollectionElement, Stringable):
    """Wrapped Error struct is just to enable the use of optional Errors."""

    var error: Error

    fn __init__(inout self, error: Error = Error()):
        self.error = error

    fn __str__(self) -> String:
        return String(self.error)


struct Result[T: CollectionElement]():
    var value: Optional[T]
    var error: Optional[WrappedError]

    fn __init__(
        inout self,
        value: T,
    ):
        self.value = value
        self.error = None
    
    fn __init__(
        inout self,
        error: Optional[WrappedError],
    ):
        self.value = None
        self.error = error
    
    fn __init__(
        inout self,
        value: T,
        error: Optional[WrappedError],
    ):
        self.value = value
        self.error = error
    
    fn is_ok(self) -> Bool:
        if self.value:
            return True
        return False
    
    fn is_err(self) -> Bool:
        if self.error:
            return True
        return False

    fn ok(self) -> Optional[T]:
        return self.value
    
    fn err(self) -> Optional[WrappedError]:
        return self.error
