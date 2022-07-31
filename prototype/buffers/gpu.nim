## GPU buffers, or the ones defined by OpenGL.

import opengl

type
    Buffer* = ref object
        handle*: uint32
        usage*: GlEnum

        occupied*, size*: int32

const
    utility = GlCopyReadBuffer

# state

proc bindTo*(buffer: Buffer, target: GlEnum) =
    glBindBuffer(target, buffer.handle)

# data

proc insert*(buffer: Buffer, item: pointer, at, width: int32, target: GlEnum = utility) =
    buffer.bindTo(target)
    glBufferSubData(target, at, width, item)

proc allocateSpace*(buffer: Buffer, target: GlEnum = utility) =
    buffer.bindTo(target)
    glBufferData(target, buffer.size, nil, buffer.usage)

# init

proc newBuffer*(usage: GlEnum, startSize: int32 = 1024): Buffer =
    ## important note: this does automatically
    ## initialize the data within the buffer

    result = new(Buffer)

    glGenBuffers(1, addr result.handle)
    result.size = startSize
    result.usage = usage

    result.allocateSpace()

# sizing

proc resize*(buffer: var Buffer, newSize: int32) =
    var temporary = newBuffer(buffer.usage, buffer.occupied)

    buffer.bindTo(GlCopyReadBuffer)
    temporary.bindTo(GlCopyWriteBuffer)

    # copy from buffer to temp
    glCopyBufferSubData(GlCopyReadBuffer, GlCopyWriteBuffer, 0, 0, buffer.occupied)

    # allocate empty memory with new size
    buffer.size = newSize
    # this is fine now, since we don't care about
    # the old data
    buffer.allocateSpace(GlCopyReadBuffer)

    # copy back from temp to newly resized buffer
    glCopyBufferSubData(GlCopyWriteBuffer, GlCopyReadBuffer, 0, 0, buffer.occupied)

    # delete the temporary buffer; as this proc should
    # be called relatively infrequently, the creation
    # and deletion should not be a performance concern
    glDeleteBuffers(1, addr temporary.handle)

proc checkSize(buffer: var Buffer, increase: int32) =
    if buffer.occupied + increase > buffer.size:
        buffer.resize(buffer.size * 2)
        buffer.checkSize(0)

# op

proc add*(buffer: var Buffer, data: pointer, width: int32): int32 =
    ## adds an object to the buffer, and returns
    ## the offset, to allow future modification
    result = buffer.occupied

    buffer.checkSize(width)

    buffer.insert(data, result, width)
    buffer.occupied += width

# debug

proc `$`*(buffer: Buffer): string =
    return "Buffer" & $buffer[]