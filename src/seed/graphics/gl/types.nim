type
    GlKind[E] = object of RootObj
        asEnum*: E

    BufferKind* = object of GlKind[uint32]
    ShaderKind* = object of GlKind[uint32]

type
    # handles and registration (such as glCreateBuffers, and the pointer accepted)

    IndirectRegister[H: SomeInteger] = proc(count: int, handle: ptr H)
    KindRegister[E, H: SomeInteger] = proc(kind: E): H
    Register[H: SomeInteger] = proc(): H

    Handled[H: SomeInteger] = object of RootObj
        handle*: H
        register*: Register[H]

    # buffers

    Buffer = object of Handled[uint32]
        kind*: BufferKind

    VertexBuffer* = object of Buffer

    ElementBuffer* = object of Buffer

    # shaders

    Compiled = object of Handled[uint32]
        # compile and link implicitly check compilation and report errors
        compile*: proc()

    Linked = object of Handled[uint32]
        link*: proc()

    Shader* = object of Compiled
        kind: ShaderKind

    ShaderProgram* = object of Linked
        vertex, fragment: Shader

#[ TODO uncomment once gl is added as a dependency
const
    vertexBuffer = BufferKind(asEnum: GL_ARRAY_BUFFER)
    elementBuffer = BufferKind(asEnum: GL_ELEMENT_BUFFER)

    vertexShader = ShaderKind(asEnum: GL_VERTEX_SHADER)
    fragmentShader = ShaderKind(asEnum: GL_FRAGMENT_SHADER)
]#

proc convert*[H: SomeInteger](register: IndirectRegister[H]): Register[H] =
    ## Convert an indirect registration proc to a direct one for more convenient/modern manual registration.
    
    # 'result = ' is necessary to make it be considered an expression
    result = proc() = 
        var handle: H
        register(1, addr handle)
        return handle

proc convert*[E, H: SomeInteger, K: GlKind[E]](kind: K, register: KindRegister[E, H]): Register[H] =
    ## Similarly, but with a registration proc requiring a type, like glCreateShader.
    result = proc() = 
        register(kind.asEnum)