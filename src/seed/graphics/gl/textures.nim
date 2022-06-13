import kinds, shared, shaders, uniforms, opengl, ../images, std/with

type
    Texture = object of Handled[uint32]
        image*: Image
        kind*: TextureKind
        channelKind*: ImageChannelKind
        uniform*: ShaderUniform[int32]

        minFilter, magFilter: TextureFiltering
        wrapping: array[3, TextureWrapping]

    Texture1* = object of Texture
    Texture2* = object of Texture1
    Texture3* = object of Texture2

# properties

## templates

template declareWrapping(textureType: typedesc, glProperty, index: typed, property: untyped) =
    proc `property =`*(texture: var textureType, wrapping: TextureWrapping) =
        glTexParameteri(texture.kind.asEnum, glProperty, wrapping.asInt)
        texture.wrapping[index] = wrapping

template declareFiltering(glProperty: typed, property: untyped) =
    proc `property =`*(texture: var Texture, filtering: TextureFiltering) =
        glTexParameteri(texture.kind.asEnum, glProperty, filtering.asInt)
        texture.`property` = filtering

## declarations

proc hasMipmaps*(texture: Texture): bool =
    result = texture.minFilter != linear and texture.minFilter != nearest

proc `slot=`*(texture: Texture, kind: ActiveTextureKind) =
    glActiveTexture(kind.asEnum)

declareWrapping(Texture1, GL_TEXTURE_WRAP_S, 0, wrapX)
declareWrapping(Texture2, GL_TEXTURE_WRAP_T, 1, wrapY)
declareWrapping(Texture3, GL_TEXTURE_WRAP_R, 2, wrapZ)

declareFiltering(GL_TEXTURE_MIN_FILTER, minFilter)
declareFiltering(GL_TEXTURE_MAG_FILTER, magFilter)

# generation

proc generate*(texture: Texture1) =
    let
        target = texture.kind.asEnum
        mipmapLevel = 0.int32
        format = rgba.asEnum
        width = texture.image.width.int32
        border = 0.int32
        dataKind = ubyteData.asEnum
        pixels = cast[pointer](unsafeAddr texture.image.data[0])

    glTexImage1D(target, mipmapLevel, format.int32, width, border, format, dataKind, pixels)

    if texture.hasMipmaps:
        glGenerateMipmap(target)

proc generate*(texture: Texture2) =
    let
        target = texture.kind.asEnum
        mipmapLevel = 0.int32
        format = rgba.asEnum
        width = texture.image.width.int32
        height = texture.image.height.int32
        border = 0.int32
        dataKind = ubyteData.asEnum
        pixels = cast[pointer](unsafeAddr texture.image.data[0])

    glTexImage2D(target, mipmapLevel, format.int32, width, height, border, format, dataKind, pixels)

    if texture.hasMipmaps:
        glGenerateMipmap(target)

proc generate*(texture: Texture3) =
    raise newException(Exception, "3D images were not accounted for, and generally break the entire system.")

# initialization

template declareTextureConstructor(constructorName: untyped, textureType: typedesc, textureKind: TextureKind) =
    proc `constructorName`*(program: ShaderProgram, name: string, textureImage: Image): textureType =
        let textureHandle = register(glGenTextures)
        let textureUniform = program.newUniform[:int32](name, samplerUniform)

        with(result):
            handle = textureHandle
            image = textureImage
            kind = textureKind
            uniform = textureUniform

declareTextureConstructor(newTexture1, Texture1, texture1)
declareTextureConstructor(newTexture2, Texture2, texture2)
declareTextureConstructor(newTexture3, Texture3, texture3)