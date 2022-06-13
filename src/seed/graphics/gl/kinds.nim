import opengl

type
    GlKind = object of RootObj
        asEnum*: GLenum

    IntKind = object of RootObj
        asInt*: int32

    # buffers

    BufferKind* = GlKind

    # shaders

    ShaderKind* = GlKind

    # rendering

    DrawKind* = GlKind

    DataKind* = object of GlKind
        size*: int

    # textures

    TextureKind* = GlKind
    ActiveTextureKind* = GlKind

    TextureWrapping* = IntKind
    TextureFiltering* = IntKind

    ImageChannelKind* = GlKind

proc newDataKind*[T](asEnum: GLenum, dataType: typedesc[T]): DataKind =
    result = DataKind(asEnum: asEnum, size: sizeof(dataType))

proc newGlKind*(asEnum: GLenum): GlKind =
    result = GlKind(asEnum: asEnum)

proc newIntKind(asInt: int32): IntKind =
    result = IntKind(asInt: asInt)

let
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

    floatData* = newDataKind(cGL_FLOAT, float32)
    ubyteData* = newDataKind(GL_UNSIGNED_BYTE, uint8)
    uintData* = newDataKind(GL_UNSIGNED_INT, uint32)

    texture1*: TextureKind = newGlKind(GL_TEXTURE_1D)
    texture2*: TextureKind = newGlKind(GL_TEXTURE_2D)
    texture3*: TextureKind = newGlKind(GL_TEXTURE_3D)

    # there are 32 available textures. I'm not doing that many.
    activeTexture0*: ActiveTextureKind = newGlKind(GL_TEXTURE0)
    activeTexture1*: ActiveTextureKind = newGlKind(GL_TEXTURE1)
    activeTexture2*: ActiveTextureKind = newGlKind(GL_TEXTURE2)

    repeat*: TextureWrapping = newIntKind(GL_REPEAT)
    mirroredRepeat*: TextureWrapping = newIntKind(GL_MIRRORED_REPEAT)
    edgeClamp*: TextureWrapping = newIntKind(GL_CLAMP_TO_EDGE)
    borderClamp*: TextureWrapping = newIntKind(GL_CLAMP_TO_BORDER)

    linear*: TextureFiltering = newIntKind(GL_LINEAR)
    nearest*: TextureFiltering = newIntKind(GL_NEAREST)

    # order is binary 00-11, where 0 is linear & 1 is nearest
    linearMipmapLinear*: TextureFiltering = newIntKind(GL_LINEAR_MIPMAP_LINEAR)
    linearMipmapNearest*: TextureFiltering = newIntKind(GL_LINEAR_MIPMAP_NEAREST)
    nearestMipmapLinear*: TextureFiltering = newIntKind(GL_NEAREST_MIPMAP_LINEAR)
    nearestMipmapNearest*: TextureFiltering = newIntKind(GL_NEAREST_MIPMAP_NEAREST)

    rgb*: ImageChannelKind = newGlKind(GL_RGB)
    rgba*: ImageChannelKind = newGlKind(GL_RGBA)