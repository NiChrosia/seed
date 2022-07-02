import shared, shaders, opengl, ../../../util/seqs, sequtils

type
    ## A representation of a shader attribute (or input), used to pack data from separate inputs into one seq
    ShaderInput* = object of RootObj
        name: string
        length: int

    ## An object for transferring data en-masse from the CPU to the GPU.
    Buffer* = ref object of Handled[uint32]
        kind*: GLenum

    VertexBuffer* = ref object of Buffer
        dataType: GLenum
        dataSize: int

        inputs*: seq[ShaderInput]

    ElementBuffer* = ref object of Buffer

    ## An object describing how vertex attributes are stored in a buffer.
    VertexArray* = ref object of Handled[uint32]
        buffers: seq[VertexBuffer]

# initialization

## inputs

proc newInput*(name: string, length: int): ShaderInput =
    return ShaderInput(name: name, length: length)

# TODO make the lengths after the height less ambiguous-looking
proc newInputs*(lengths: varargs[tuple[name: string, length: int]]): seq[ShaderInput] =
    for pair in lengths:
        let (name, length) = pair

        result.add(newInput(name, length))

## buffers

proc newVertexBuffer*[T](dataType: typedesc[T], dataEnum: GLenum, inputs: seq[ShaderInput]): VertexBuffer =
    let handle = register(glCreateBuffers)

    return VertexBuffer(handle: handle, kind: GL_ARRAY_BUFFER, dataType: dataEnum, dataSize: sizeof(dataType), inputs: inputs)

proc newElementBuffer*(): ElementBuffer =
    let handle = register(glCreateBuffers)

    return ElementBuffer(handle: handle, kind: GL_ELEMENT_ARRAY_BUFFER)

## vertex arrays

proc newVertexArray*(buffers: seq[VertexBuffer]): VertexArray =
    let handle = register(glCreateVertexArrays)
    return VertexArray(handle: handle, buffers: buffers)

# shader attributes

proc inputPointer*(index, length, stride, offset: int, dataType: GLenum, normalized: bool) =
    glVertexAttribPointer(index.uint32, length.int32, dataType, normalized, stride.int32, cast[pointer](offset))

proc configurePointer*(buffer: VertexBuffer, program: ShaderProgram, array: VertexArray) =
    for index in 0 ..< buffer.inputs.len:
        let input = buffer.inputs[index]

        let totalLength = buffer.inputs.mapIt(it.length).sum()

        let indicesBefore = buffer.inputs.indices.filterIt(it < index)
        let itemsBefore = indicesBefore.mapIt(buffer.inputs[it])
        let lengthBefore = itemsBefore.mapIt(it.length).sum()

        let stride = totalLength.int32 * buffer.dataSize
        let offset = lengthBefore * buffer.dataSize

        glBindAttribLocation(program.handle, index.uint32, input.name.cstring)
        inputPointer(index, input.length, stride, offset, buffer.dataType, false)
        glEnableVertexAttribArray(index.uint32)

proc configurePointers*(array: VertexArray, program: ShaderProgram) =
    for buffer in array.buffers:
        buffer.configurePointer(program, array)

# CPU-to-GPU communication

proc pack*[T](buffer: VertexBuffer, data: seq[seq[T]]): seq[T] =
    var height = data[0].len div buffer.inputs[0].length

    for index in 1 ..< data.len:
        let dataLength = data[index].len
        let inputLength = buffer.inputs[index].length

        let newHeight = dataLength div inputLength

        if newHeight != height:
            raise newException(Exception, "Given data has mismatching height!")
        else:
            height = newHeight

    for y in 0 ..< height:
        for index in 0 ..< buffer.inputs.len:
            let input = buffer.inputs[index]
            let subdata = data[index]

            for x in 0 ..< input.length:
                let pos = x + y * input.length
                let item = subdata[pos]

                result.add(item)

proc send*[T](buffer: VertexBuffer, usage: GLenum, data: seq[seq[T]]) =
    let packed = buffer.pack(data)

    glBufferData(buffer.kind, packed.len * sizeof(packed), unsafeAddr(packed[0]), usage)

proc send*(buffer: ElementBuffer, usage: GLenum, data: seq[uint32]) =
    glBufferData(buffer.kind, data.len * sizeof(uint32), unsafeAddr(data[0]), usage)