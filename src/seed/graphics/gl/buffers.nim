import shared, kinds, opengl

type
    ## An object for transferring data en-masse from the CPU to the GPU.
    Buffer* = object of Handled[uint32]
        kind*: BufferKind

# initialization

proc newBuffer*(kind: BufferKind): Buffer =
    let handle = register(glCreateBuffers)
    result = Buffer(handle: handle)

proc newVertexBuffer*(): Buffer = 
    result = newBuffer(vertexBuffer)

proc newElementBuffer*(): Buffer = 
    result = newBuffer(elementBuffer)

# CPU-to-GPU communication

proc send*[T](buffer: Buffer, data: openArray[T], usage: DrawKind) = 
    glBufferData(buffer.kind, data.len * sizeof(T), unsafeAddr(data), usage)