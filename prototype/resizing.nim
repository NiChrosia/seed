import windy, opengl, std/[times]

template benchmark(task: string, body: untyped) =
    var average = 0f

    for i in 1 .. 1_000_000:
        let start = cpuTime()

        body

        let stop = cpuTime()
        let duration = stop - start

        if average != 0:
            average = (average + duration) / 2
        else:
            average = duration

    echo "Time taken for ", task, ": ", average

proc subdata[T](id: uint32, size: int32, offset: int32 = 0): ptr T =
    var data = cast[ptr T](alloc(size))

    glGetNamedBufferSubData(id, offset, size, data)

    return data

proc resize[T](id: uint32, before, after: int32, usage: GLenum) =
    var data = glMapNamedBuffer(id, GL_READ_WRITE)

    # resetting buffer data automatically unmaps the buffer, 
    # so such a call is unnecessary (and causes an error, anyway)
    glNamedBufferData(id, after, data, usage)

proc resize_newBuffer[T](id: uint32, before, after: int32, usage: GLenum): uint32 =
    glGenBuffers(1, addr result)
    glBindBuffer(GL_COPY_WRITE_BUFFER, result)
    glBufferData(GL_COPY_WRITE_BUFFER, after, nil, usage)

    glBindBuffer(GL_COPY_READ_BUFFER, id)
    glBindBuffer(GL_COPY_WRITE_BUFFER, result)
    glCopyBufferSubData(GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, 0, 0, before)

proc print[T](id: uint32, size: int32, offset: int32 = 0) =
    echo subdata[T](id, size, offset)[]

let window = newWindow("Test", ivec2(800, 600), openglMajorVersion = 4, openglMinorVersion = 5)

window.makeContextCurrent()
loadExtensions()

var data = int32(1)

var buffer: uint32
glGenBuffers(1, addr buffer)

glBindBuffer(GL_ARRAY_BUFFER, buffer)
glBufferData(GL_ARRAY_BUFFER, 4, addr data, GL_DYNAMIC_DRAW)

print[int32](buffer, 4)

benchmark "map based resize":
    resize[int32](buffer, 4, 8, GL_DYNAMIC_DRAW)

benchmark "new buffer based resize":
    buffer = resize_newBuffer[int32](buffer, 8, 8, GL_DYNAMIC_DRAW)

var newData = int32(2)

glBufferSubData(GL_ARRAY_BUFFER, 4, 4, addr newData)

print[int32](buffer, 4)
print[int32](buffer, 4, 4)