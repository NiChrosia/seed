import shared, opengl

type
    ## An object describing how vertex attributes are stored in a buffer.
    VertexArray* = object of Handled[uint32]

# initialization

proc newVertexArray*(): VertexArray =
    let handle = register(glCreateVertexArrays)
    result = VertexArray(handle: handle)