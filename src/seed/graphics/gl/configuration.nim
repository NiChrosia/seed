import types, opengl

# initialization

proc newVertexArray*(): VertexArray =
    let handle = register(glCreateVertexArrays)
    result = VertexArray(handle: handle)