import opengl

type
    GlKind = object of RootObj
        asEnum*: GLenum

    BufferKind* = GlKind
    ShaderKind* = GlKind
    DrawKind* = GlKind

    DataKind* = object of GlKind
        size*: int

proc newDataKind*[T](asEnum: GLenum, dataType: typedesc[T]): DataKind =
    result = DataKind(asEnum: asEnum, size: sizeof(dataType))

proc newGlKind*(asEnum: GLenum): GlKind =
    result = GlKind(asEnum: asEnum)

let
    floatData* = newDataKind(cGL_FLOAT, float32)
    uintData* = newDataKind(GL_UNSIGNED_INT, uint32)

    arrayBuffer*: BufferKind = newGlKind(GL_ARRAY_BUFFER)
    elementArrayBuffer*: BufferKind = newGlKind(GL_ELEMENT_ARRAY_BUFFER)

    vertexShader*: ShaderKind = newGlKind(GL_VERTEX_SHADER)
    fragmentShader*: ShaderKind = newGlKind(GL_FRAGMENT_SHADER)

    # set once, used a few times
    streamDraw*: DrawKind = newGlKind(GL_STREAM_DRAW)
    # set once, used many times
    staticDraw*: DrawKind = newGlKind(GL_STATIC_DRAW)
    # set many times, used many times
    dynamicDraw*: DrawKind = newGlKind(GL_DYNAMIC_DRAW)