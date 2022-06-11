import opengl, tables

type
    # TODO reimplement this system, as manualy declaring conversions & memory sizes is ugly and inelegant
    DataKind* = enum
        floatData, uintData

    BufferKind* = enum
        arrayBuffer, elementArrayBuffer

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

proc size*(dataKind: DataKind): int =
    {.warning[UnreachableElse]: off.}
    result = case dataKind:
    of floatData:
        sizeof(float32)
    of uintData:
        sizeof(uint32)
    else:
        raise newException(ValueError, "Given data kind does not have a memory size associated with it. Add one!")

declareConversion(DataKind, GLenum, {
    floatData: cGL_FLOAT
})

declareConversion(BufferKind, GLenum, {
    arrayBuffer: GL_ARRAY_BUFFER,
    elementArrayBuffer: GL_ELEMENT_ARRAY_BUFFER
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