import opengl

type
    BufferBackedSeq*[T] = object
        capacity: int
        buffer: GLuint

        data: seq[T]
        dirty: bool

    OutOfBoundsError = object of ValueError

proc init*[T](_: typedesc[BufferBackedSeq], buffer: GLuint, capacity: int = 1024): BufferBackedSeq[T] =
    result.capacity = capacity
    result.buffer = buffer

    result.data = newSeqOfCap[T](capacity)
    result.dirty = false

proc update*[T](seq: var BufferBackedSeq[T]) =
    if not seq.dirty:
        return

    glNamedBufferSubData(seq.buffer, 0, seq.data.len * sizeof(T), addr seq.data[0])
    seq.dirty = false

proc add*[T](seq: var BufferBackedSeq[T], elements: openArray[T]) =
    # in what scenario would someone even do this, though?
    if elements.len == 0:
        return

    if seq.len + elements.len > seq.capacity:
        raise OutOfBoundsError.newException("Not enough space for elements in buffer-backed seq!")

    copyMem(addr seq.data[seq.data.len], unsafeAddr elements[0], elements.len * sizeof(T))
    seq.dirty = true

proc add*[T](seq: var BufferBackedSeq[T], element: T) =
    if seq.len + 1 > seq.capacity:
        raise OutOfBoundsError.newException("No more space left in buffer-backed seq!")

    seq.data.add(element)
    seq.dirty = true

proc len*[T](seq: BufferBackedSeq[T]): int =
    return seq.data.len
