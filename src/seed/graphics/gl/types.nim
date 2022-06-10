import kinds

type
    Handled[H: SomeInteger] = object of RootObj
        handle*: H
        register*: proc(): H

    # configuration

    ## An object describing how vertex attributes are stored in a buffer.
    VertexArray* = object of Handled[uint32]

    # buffers

    ## An object for transferring data en-masse from the CPU to the GPU.
    Buffer* = object of Handled[uint32]
        kind*: BufferKind

    # shaders

    Compiled = object of Handled[uint32]
        # compile and link implicitly check compilation and report errors
        compile*: proc()

    Linked = object of Handled[uint32]
        link*: proc()

    Shader* = object of Compiled
        kind*: ShaderKind

    ShaderProgram* = object of Linked
        vertex*, fragment*: Shader

proc register*[H: SomeInteger](function: proc(count: int32, handles: ptr H) {.stdcall.}): H = 
    var handle: H
    function(1, addr handle)
    result = handle