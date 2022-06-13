import shared, kinds, buffers, shaders, textures, opengl, tables, variant

let active = newTable[TypeId, bool]([])

# usage

template declareUsage(bindProc: typed, usedType: typedesc) =
    let id = getTypeId(usedType)

    proc use*(item: usedType) =
        active[id] = true
        bindProc(item.handle)

    proc dismiss*(itemType: typedesc[usedType]) =
        active[id] = false
        bindProc(0)

    # explicitly uses the `usedType` rather than `typed` to avoid conflicts with the standard library's `with`
    template with*(item: usedType, shouldDismiss: typed, body: varargs[untyped]) =
        use(item)

        body

        if shouldDismiss:
            dismiss(usedType)

template declareTypedUsage(kind, bindProc: typed, itemType: typedesc) =
    declareUsage(proc(handle: uint32) = bindProc(kind.asEnum, handle), itemType)

template declareBufferUsage(kind: BufferKind, bufferType: typedesc) =
    declareTypedUsage(kind, glBindBuffer, bufferType)

template declareTextureUsage(kind: TextureKind, textureType: typedesc) =
    declareTypedUsage(kind, glBindTexture, textureType)

# activity

# intended to be used as Type.isActive
proc isActive*[T](itemType: typedesc[T]): bool =
    let id = getTypeId(itemType)
    result = active[id]

# declarations

declareUsage(glBindVertexArray, VertexArray)
declareUsage(glUseProgram, ShaderProgram)

declareBufferUsage(arrayBuffer, VertexBuffer)
declareBufferUsage(elementArrayBuffer, ElementBuffer)

declareTextureUsage(texture1, Texture1)
declareTextureUsage(texture2, Texture2)
declareTextureUsage(texture3, Texture3)