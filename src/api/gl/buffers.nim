import opengl

type
    Buffer* = object
        handle*: uint32
        used*, capacity*: int32
        usage*: GLenum

proc init*(_: typedesc[Buffer], usage: GLenum): Buffer =
    glGenBuffers(1, addr result.handle)

    result.usage = usage
    result.capacity = 1024

    glBindBuffer(GL_COPY_READ_BUFFER, result.handle)
    glBufferData(GL_COPY_READ_BUFFER, result.capacity, nil, usage)

proc resize*(b: var Buffer, factor: float32 = 2f) =
    ## warning: this does use the gl copy read & write buffers
    ## so make sure they're empty

    let new = int32(float32(b.capacity) * factor)

    glBindBuffer(GL_COPY_READ_BUFFER, b.handle)
    let mappedData = glMapBuffer(GL_COPY_READ_BUFFER, GL_READ_ONLY)

    let data = alloc(b.used)
    copyMem(data, mappedData, b.used)

    assert glUnmapBuffer(GL_COPY_READ_BUFFER), "unmapping failed!"

    glBufferData(GL_COPY_READ_BUFFER, new, data, b.usage)

    b.capacity = new

proc add*(b: var Buffer, size: int32, data: pointer) =
    while b.used + size > b.capacity:
        b.resize()

    glBindBuffer(GL_COPY_READ_BUFFER, b.handle)
    glBufferSubData(GL_COPY_READ_BUFFER, b.used, size, data)

    b.used += size

proc add*[I](b: var Buffer, size: I, data: pointer) =
    b.add(int32(size), data)
