import opengl, tables

type
    BufferKind* = enum
        vertexBuffer, elementBuffer

    ShaderKind* = enum
        vertexShader, fragmentShader

    DrawKind* = enum
        staticDraw

template declareConversion(kindType, enumType: typed, table: untyped) = 
    proc asEnum*(kind: kindType): enumType = 
        result = table[kind]

declareConversion(BufferKind, GLenum, {
    vertexBuffer: GL_ARRAY_BUFFER,
    elementBuffer: GL_ELEMENT_ARRAY_BUFFER
}.toTable)

declareConversion(ShaderKind, GLenum, {
    vertexShader: GL_VERTEX_SHADER,
    fragmentShader: GL_FRAGMENT_SHADER
}.toTable)

declareConversion(DrawKind, GlEnum, {
    staticDraw: GL_STATIC_DRAW
}.toTable)