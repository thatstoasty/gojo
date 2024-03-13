from collections.optional import Optional


@value
struct WrappedError(CollectionElement, Stringable):
    """Wrapped Error struct is just to enable the use of optional Errors."""

    var error: Error

    fn __init__(inout self, error: Error = Error()):
        self.error = error
    
    fn __init__[T: Stringable](inout self, message: T):
        self.error = Error(message)

    fn __str__(self) -> String:
        return String(self.error)


@value
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
    
    fn has_value(self) -> Bool:
        if self.value:
            return True
        return False
    
    fn has_error(self) -> Bool:
        if self.error:
            return True
        return False
    
    fn has_both(self) -> Bool:
        if self.value and self.error:
            return True
        return False

    fn get_value(self) -> T:
        return self.value.value()
    
    fn get_error(self) -> WrappedError:
        return self.error.value()
