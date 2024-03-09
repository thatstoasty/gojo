"""From https://github.com/mikowals/dynamic_vector.mojo/blob/main/dynamic_vector.mojo"""

from memory.anypointer import AnyPointer


struct DynamicVector[T: CollectionElement](Sized, CollectionElement):
    var data: AnyPointer[T]
    var size: Int
    var capacity: Int

    @always_inline
    fn __init__(inout self, *, capacity: Int = 0):
        self.capacity = capacity
        self.data = AnyPointer[T].alloc(capacity)
        self.size = 0

    @always_inline
    fn __del__(owned self):
        for i in range(self.size):
            _ = (self.data + i).take_value()
        self.data.free()

    @always_inline
    fn __copyinit__(inout self, other: Self):
        self.capacity = other.capacity
        self.size = other.size
        self.data = AnyPointer[T].alloc(self.capacity)
        for i in range(self.size):
            var new_value = other[i]
            (self.data + i).emplace_value(new_value)

    @always_inline
    fn __moveinit__(inout self, owned other: Self):
        self.capacity = other.capacity
        self.size = other.size
        self.data = other.data
        other.data = AnyPointer[T]()
        other.size = 0
        other.capacity = 0

    fn append(inout self, owned value: T):
        if self.size == self.capacity:
            self.reserve(self.capacity * 2)
        Reference(self.data.__refitem__(self.size))[] = value ^
        self.size += 1
    
    fn extend(inout self, other: Self):
        self.reserve(self.size + len(other))
        for i in range(len(other)):
            self.append(other[i])

    fn push_back(inout self, owned value: T):
        self.append(value ^)

    @always_inline
    fn pop_back(inout self) -> T:
        self.size -= 1
        return (self.data + self.size).take_value()

    @always_inline
    fn __refitem__(
        inout self, index: Int
    ) -> Reference[T, __mlir_attr.`1: i1`, __lifetime_of(self)]:
        return self.data.__refitem__(index)

    @always_inline
    fn reserve(inout self, new_capacity: Int):
        if new_capacity <= self.capacity:
            return
        var new_data = AnyPointer[T].alloc(new_capacity)
        for i in range(self.size):
            (self.data + i).move_into(new_data + i)
        self.data.free()
        self.data = new_data
        self.capacity = new_capacity

    @always_inline
    fn resize(inout self, new_size: Int, value: T):
        if new_size > self.size:
            if new_size > self.capacity:
                self.reserve(new_size)
            for _ in range(self.size, new_size):
                self.append(value)

    @always_inline
    fn __getitem__(self, index: Int) -> T:
        return __get_address_as_lvalue((self.data + index).value)

    @always_inline
    fn __getitem__(
        inout self, _slice: Slice
    ) -> DynamicVectorSlice[T, __lifetime_of(self)]:
        return DynamicVectorSlice[T](Reference(self), _slice)

    @always_inline
    fn __setitem__(inout self, index: Int, owned value: T):
        self.__refitem__(index)[] = value

    @always_inline
    fn __len__(self) -> Int:
        return self.size


@value
struct DynamicVectorSlice[T: CollectionElement, L: MutLifetime](
    Sized, CollectionElement
):
    var data: Reference[DynamicVector[T], __mlir_attr.`1: i1`, L]
    var _slice: Slice
    var size: Int

    @always_inline
    fn __init__(
        inout self,
        data: Reference[DynamicVector[T], __mlir_attr.`1: i1`, L],
        _slice: Slice,
    ):
        self.data = data
        self._slice = Self.adapt_slice(_slice, len(data[]))
        self.size = Self.get_size(self._slice.start, self._slice.end, self._slice.step)

    @always_inline
    fn __init__(
        inout self,
        other: Self,
        _slice: Slice,
    ):
        self.data = other.data
        self._slice = Self.adapt_slice(_slice, other._slice, len(other))
        self.size = Self.get_size(self._slice.start, self._slice.end, self._slice.step)

    @always_inline
    fn __getitem__(self, index: Int) -> T:
        var underlying_index = self._slice.start + index * self._slice.step
        if underlying_index >= self._slice.end:
            print(
                "slice index out of range.  Index ",
                underlying_index,
                "is outside range",
                self._slice.start,
                "-",
                self._slice.end,
                ".",
            )
        return self.data[][self._slice.start + index * self._slice.step]

    @always_inline
    fn __getitem__(inout self, _slice: Slice) -> Self:
        return Self(self, _slice)

    @always_inline
    fn __setitem__(inout self, index: Int, owned value: T):
        self.data[][self._slice.start + index * self._slice.step] = value ^

    @always_inline
    fn __len__(self) -> Int:
        return self.size

    @always_inline
    fn to_vector(self) -> DynamicVector[T]:
        var res = DynamicVector[T](capacity=len(self))
        for i in range(len(self)):
            res.append(self[i])
        return res

    @always_inline
    @staticmethod
    fn adapt_slice(_slice: Slice, dim: Int) -> Slice:
        var res = _slice
        if res.start < 0:
            res.start += dim
        if not _slice._has_end():
            res.end = dim
        if res.end < 0:
            res.end += dim
        if res.end > dim:
            res.end = dim

        if res.end < res.start:
            res.end = res.start

        return res

    @always_inline
    @staticmethod
    fn adapt_slice(_slice: Slice, base_slice: Slice, dim: Int) -> Slice:
        var res = Self.adapt_slice(_slice, dim)
        res.start = base_slice.start + res.start * base_slice.step
        res.end = base_slice.start + res.end * base_slice.step
        res.step *= base_slice.step

        return res

    @always_inline
    fn __setitem__(inout self, _slice: Slice, owned value: Self):
        var base_slice = Self.adapt_slice(_slice, self._slice, len(self))
        if len(value) != (base_slice.end - base_slice.start) // base_slice.step:
            print(
                "slice assignment size mismatch",
                len(value),
                (base_slice.end - base_slice.start) // base_slice.step,
                base_slice.start,
                base_slice.end,
                base_slice.step,
            )
            return

        for i in range((_slice.end - _slice.start) // _slice.step):
            var dest = self.data[].data + base_slice.start + i * base_slice.step
            _ = (dest).take_value()
            (value.data[].data + i).move_into(dest)

    @always_inline
    fn __setitem__[
        l: MutLifetime
    ](inout self, _slice: Slice, owned value: DynamicVectorSlice[T, l]):
        var base_slice = Self.adapt_slice(_slice, self._slice, len(self))
        if len(value) != (base_slice.end - base_slice.start) // base_slice.step:
            print(
                "slice assignment size mismatch",
                len(value),
                (base_slice.end - base_slice.start) // base_slice.step,
                base_slice.start,
                base_slice.end,
                base_slice.step,
            )
            return

        for i in range((_slice.end - _slice.start) // _slice.step):
            var dest = self.data[].data + base_slice.start + i * base_slice.step
            var src = value.data[].data + value._get_base_offset(0, i)
            _ = (dest).take_value()
            src.move_into(dest)

    @always_inline
    fn _get_base_offset(self, start: Int, steps: Int, stride: Int = 1) -> Int:
        return self._slice.start + start + steps * self._slice.step * stride

    @always_inline
    @staticmethod
    fn get_size(start: Int, end: Int, step: Int) -> Int:
        return math.max(0, (end - start + (step - (1 if step > 0 else -1))) // step)