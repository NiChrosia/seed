import types, opengl

# initialization

proc newVertexArray*(): VertexArray =
    let handle = register[uint32](glCreateVertexArrays)
    result = VertexArray(handle: handle)