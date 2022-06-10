import shared, opengl

type
    ## An object describing how vertex attributes are stored in a buffer.
    VertexArray* = object of Handled[uint32]

# initialization

proc newVertexArray*(): VertexArray =
    let handle = register(glCreateVertexArrays)
    result = VertexArray(handle: handle)

# TODO implement a system for sending configured data to buffers using a vertex array.
# It needs to be automatically formatted data like
#[
    [AAA]
    [AAA]
    [AAA],
    [BB]
    [BB]
    [BB],
    [C]
    [C]
    [C]

    to

    [AAA BB C
     AAA BB C
     AAA BB C]
]#
# and in an idiomatic way