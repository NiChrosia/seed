import ../shared, ../buffers, ../shaders, ../textures, opengl, activity, std/tables

# usage

template declareUsage(bindProc: typed, usedType: typedesc) =
    proc use*(item: usedType) =
        usedType.active = true
        bindProc(item.handle)

    proc dismiss*(itemType: typedesc[usedType]) =
        usedType.active = false
        bindProc(0)

    # explicitly uses the `usedType` rather than `typed` to avoid conflicts with the standard library's `with`
    template with*(item: usedType, shouldDismiss: bool, body: varargs[untyped]) =
        use(item)

        body

        if shouldDismiss:
            dismiss(usedType)

template declareTypedUsage(kind, bindProc: typed, itemType: typedesc) =
    declareUsage(proc(handle: uint32) = bindProc(kind, handle), itemType)

template declareBufferUsage(kind: GLenum, bufferType: typedesc) =
    declareTypedUsage(kind, glBindBuffer, bufferType)

# written by code
let slotConversions = {
    0: GL_TEXTURE0,
    1: GL_TEXTURE1,
    2: GL_TEXTURE2,
    3: GL_TEXTURE3,
    4: GL_TEXTURE4,
    5: GL_TEXTURE5,
    6: GL_TEXTURE6,
    7: GL_TEXTURE7,
    8: GL_TEXTURE8,
    9: GL_TEXTURE9,
    10: GL_TEXTURE10,
    11: GL_TEXTURE11,
    12: GL_TEXTURE12,
    13: GL_TEXTURE13,
    14: GL_TEXTURE14,
    15: GL_TEXTURE15,
    16: GL_TEXTURE16,
    17: GL_TEXTURE17,
    18: GL_TEXTURE18,
    19: GL_TEXTURE19,
    20: GL_TEXTURE20,
    21: GL_TEXTURE21,
    22: GL_TEXTURE22,
    23: GL_TEXTURE23,
    24: GL_TEXTURE24,
    25: GL_TEXTURE25,
    26: GL_TEXTURE26,
    27: GL_TEXTURE27,
    28: GL_TEXTURE28,
    29: GL_TEXTURE29,
    30: GL_TEXTURE30,
    31: GL_TEXTURE31
}.toTable

template declareTextureUsage(kind: GLenum, textureType: typedesc) =
    declareTypedUsage(kind, glBindTexture, textureType)

    proc use*(texture: textureType, slot: int) =
        let asEnum = slotConversions[slot]

        texture.slot = asEnum
        use(texture)

# declarations

declareUsage(glBindVertexArray, VertexArray)
declareUsage(glUseProgram, ShaderProgram)

declareBufferUsage(GL_ARRAY_BUFFER, VertexBuffer)
declareBufferUsage(GL_ELEMENT_ARRAY_BUFFER, ElementBuffer)

declareTextureUsage(GL_TEXTURE_1D, Texture1)
declareTextureUsage(GL_TEXTURE_2D, Texture2)
declareTextureUsage(GL_TEXTURE_3D, Texture3)