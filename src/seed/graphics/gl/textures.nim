import shared, shaders, uniforms, opengl, ../images, std/with

type
    Texture = object of Handled[uint32]
        image*: Image
        kind*: GLenum

        minFilter, magFilter: int32
        wrapping: array[3, int32]

    Texture1* = object of Texture
    Texture2* = object of Texture1
    Texture3* = object of Texture2

# properties

## templates

template declareWrapping(textureType: typedesc, glProperty, index: typed, property: untyped) =
    proc `property =`*(texture: var textureType, wrapping: int32) =
        glTexParameteri(texture.kind, glProperty, wrapping)
        texture.wrapping[index] = wrapping

template declareFiltering(glProperty: typed, property: untyped) =
    proc `property =`*(texture: var Texture, filtering: int32) =
        glTexParameteri(texture.kind, glProperty, filtering)
        texture.`property` = filtering

## declarations

proc hasMipmaps*(texture: Texture): bool =
    result = texture.minFilter != GL_LINEAR and texture.minFilter != GL_NEAREST

proc `slot=`*(texture: Texture, kind: GLenum) =
    glActiveTexture(kind)

declareWrapping(Texture1, GL_TEXTURE_WRAP_S, 0, wrapX)
declareWrapping(Texture2, GL_TEXTURE_WRAP_T, 1, wrapY)
declareWrapping(Texture3, GL_TEXTURE_WRAP_R, 2, wrapZ)

declareFiltering(GL_TEXTURE_MIN_FILTER, minFilter)
declareFiltering(GL_TEXTURE_MAG_FILTER, magFilter)

# generation

proc generate*(texture: Texture1, mipmapLevel, border: int32 = 0, format: GLenum = GL_RGBA, data: GLenum = GL_UNSIGNED_BYTE) =
    let
        target = texture.kind
        width = texture.image.width.int32
        pixels = unsafeAddr(texture.image.data[0])

    glTexImage1D(target, mipmapLevel, format.int32, width, border, format, data, pixels)

    if texture.hasMipmaps:
        glGenerateMipmap(target)

proc generate*(texture: Texture2, mipmapLevel, border: int32 = 0, format: GLenum = GL_RGBA, data: GLenum = GL_UNSIGNED_BYTE) =
    let
        target = texture.kind
        width = texture.image.width.int32
        height = texture.image.height.int32
        pixels = unsafeAddr(texture.image.data[0])

    glTexImage2D(target, mipmapLevel, format.int32, width, height, border, format, data, pixels)

    if texture.hasMipmaps:
        glGenerateMipmap(target)

proc generate*(texture: Texture3) =
    raise newException(Exception, "3D images were not accounted for, and generally break the entire system.")

# initialization

template declareTextureConstructor(constructorName: untyped, textureType: typedesc, textureKind: GLenum) =
    proc `constructorName`*(textureImage: Image): textureType =
        let textureHandle = register(glGenTextures)

        with(result):
            handle = textureHandle
            image = textureImage
            kind = textureKind

proc newTextureUniform*(program: ShaderProgram, name: string): ShaderUniform[int32] =
    result = program.newUniform(name, updateTextureId)

declareTextureConstructor(newTexture1, Texture1, GL_TEXTURE_1D)
declareTextureConstructor(newTexture2, Texture2, GL_TEXTURE_2D)
declareTextureConstructor(newTexture3, Texture3, GL_TEXTURE_3D)