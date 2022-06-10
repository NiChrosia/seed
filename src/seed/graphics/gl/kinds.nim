import opengl, tables

type
    BufferKind* = enum
        vertexBuffer, elementBuffer

    ShaderKind* = enum
        vertexShader, fragmentShader

    DrawKind* = enum
        # set once, used a few times
        streamDraw,
        # set once, used many times
        staticDraw,
        # set many times, used many times
        dynamicDraw

template declareConversion(kindType, enumType: typed, tuples: untyped) =
    let table = tuples.toTable

    proc asEnum*(kind: kindType): enumType = 
        result = table[kind]

declareConversion(BufferKind, GLenum, {
    vertexBuffer: GL_ARRAY_BUFFER,
    elementBuffer: GL_ELEMENT_ARRAY_BUFFER
})

declareConversion(ShaderKind, GLenum, {
    vertexShader: GL_VERTEX_SHADER,
    fragmentShader: GL_FRAGMENT_SHADER
})

declareConversion(DrawKind, GlEnum, {
    streamDraw: GL_STREAM_DRAW,
    staticDraw: GL_STATIC_DRAW,
    dynamicDraw: GL_DYNAMIC_DRAW
})