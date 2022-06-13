import shared, kinds, buffers, shaders, opengl, tables, variant

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

template declareBufferUsage(kind: BufferKind, bufferType: typedesc) =
    declareUsage(proc(handle: uint32) = glBindBuffer(kind.asEnum, handle), bufferType)

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