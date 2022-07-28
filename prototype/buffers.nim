import opengl, windy

type
    Buffer* = ref object
        handle*: uint32
        usage*: GlEnum

        occupied*, size*: int32

const utilityBuffer = GlCopyReadBuffer

# state

proc bindTo*(buffer: Buffer, target: GlEnum) =
    glBindBuffer(target, buffer.handle)

# data

# TODO remove this legacy code and reimplement it in the functions below
proc setSlice(handle: uint32, offset, size: int32, data: pointer) =
    glBindBuffer(utilityBuffer, handle)
    glBufferSubData(utilityBuffer, offset, size, data)

proc setWhole(handle: uint32, size: int32, data: pointer, usage: GlEnum) =
    glBindBuffer(utilityBuffer, handle)
    glBufferData(utilityBuffer, size, data, usage)

proc allocateWhole(handle: uint32, newSize: int32, usage: GlEnum) =
    setWhole(handle, newSize, nil, usage)
# end TODO

# - user-friendly data procs

proc setSlice*[T](buffer: Buffer, offset: int32, item: T) =
    let size = int32(sizeof(T))

    setSlice(buffer.handle, offset, size, unsafeAddr item)

proc setWhole*(buffer: Buffer, size: int32, data: pointer) =
    setWhole(buffer.handle, size, data, buffer.usage)

proc allocateWhole*(buffer: Buffer, newSize: int32) =
    allocateWhole(buffer.handle, newSize, buffer.usage)

# init

proc newBuffer*(usage: GlEnum, startSize: int32 = 1024): Buffer =
    result = new(Buffer)

    glGenBuffers(1, addr result.handle)
    result.size = startSize
    result.usage = usage

    result.allocateWhole(startSize)

# sizing

proc resize*(buffer: var Buffer, newSize: int32) =
    var temporary = newBuffer(buffer.usage, buffer.occupied)

    buffer.bindTo(GlCopyReadBuffer)
    temporary.bindTo(GlCopyWriteBuffer)

    # copy from buffer to temp
    glCopyBufferSubData(GlCopyReadBuffer, GlCopyWriteBuffer, 0, 0, buffer.occupied)

    # allocate empty memory with new size
    buffer.allocateWhole(newSize)
    buffer.size = newSize

    # copy back from temp to newly resized buffer
    glCopyBufferSubData(GlCopyWriteBuffer, GlCopyReadBuffer, 0, 0, buffer.occupied)

    # delete the temporary buffer; as this proc should
    # be called relatively infrequently, the creation
    # and deletion should not be a performance concern
    glDeleteBuffers(1, addr temporary.handle)

proc checkSize(buffer: var Buffer, increase: int32) =
    if buffer.occupied + increase > buffer.size:
        buffer.resize(buffer.size * 2)

# op

proc add*[S](buffer: var Buffer, shape: S): int32 =
    ## adds an object to the buffer, and returns
    ## the offset, to allow future modification
    result = buffer.occupied

    let size = int32(sizeof(S))

    buffer.checkSize(size)

    buffer.setSlice(buffer.occupied, shape)
    buffer.occupied += size

# debug

proc `$`*(buffer: Buffer): string =
    return "Buffer" & $buffer[]