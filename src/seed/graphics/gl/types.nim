import opengl

type
    GlKind*[E] = object of RootObj
        asEnum*: E

    BufferKind* = object of GlKind[GLenum]
    ShaderKind* = object of GlKind[GLenum]
    DrawKind* = object of GlKind[GLenum]

type
    Handled[H: SomeInteger] = object of RootObj
        handle*: H
        register*: proc(): H

    # configuration

    VertexArray* = object of Handled[uint32]

    # buffers

    Buffer* = object of Handled[uint32]
        kind*: BufferKind

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

# declarations via 'let' because you can't properly create enums with fields
let
    vertexBuffer* = BufferKind(asEnum: GL_ARRAY_BUFFER)
    elementBuffer* = BufferKind(asEnum: GL_ELEMENT_ARRAY_BUFFER)

    vertexShader* = ShaderKind(asEnum: GL_VERTEX_SHADER)
    fragmentShader* = ShaderKind(asEnum: GL_FRAGMENT_SHADER)

    staticDraw* = DrawKind(asEnum: GL_STATIC_DRAW)

converter toEnum*[E](kind: GlKind[E]): E = 
    result = kind.asEnum

proc register*[H: SomeInteger](function: proc(count: int32, handles: ptr H) {.stdcall.}): H = 
    var handle: H
    function(1, addr handle)
    result = handle

proc register*[E; H: SomeInteger, K: GlKind[E]](kind: K, function: proc(kind: E): H {.stdcall.}): H = 
    result = function(kind)