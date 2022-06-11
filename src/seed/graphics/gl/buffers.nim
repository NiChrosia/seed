import shared, kinds, shaders, opengl, ../../util/seqs, sequtils

type
    ## A representation of a shader attribute (or input), used to pack data from separate inputs into one seq
    ShaderInput* = object of RootObj
        name: string
        length, height: int

    ## An object for transferring data en-masse from the CPU to the GPU.
    Buffer* = ref object of Handled[uint32]
        kind*: BufferKind
        dataKind*: DataKind

        inputs*: seq[ShaderInput]

    ## An object describing how vertex attributes are stored in a buffer.
    VertexArray* = ref object of Handled[uint32]
        buffers: seq[Buffer]

# initialization

## inputs

proc newInput*(name: string, height, length: int): ShaderInput =
    result = ShaderInput(name: name, length: length, height: height)

# TODO make the lengths after the height less ambiguous-looking
proc newInputs*(height: int, lengths: varargs[tuple[name: string, length: int]]): seq[ShaderInput] =
    for pair in lengths:
        let (name, length) = pair

        result.add(newInput(name, length, height))

## buffers

# ensure all the heights are the same, to ensure data integrity
proc verifyHeights(inputs: seq[ShaderInput]) =
    var height = inputs[0].height

    for index in 1 ..< inputs.len:
        let nextHeight = inputs[index].height

        if height == nextHeight:
            height = nextHeight
        else:
            raise newException(ValueError, "Given inputs do not match in height!")

proc newBuffer*(kind: BufferKind, inputs: seq[ShaderInput]): Buffer =
    let handle = register(glCreateBuffers)
    verifyHeights(inputs)

    result = Buffer(handle: handle, inputs: inputs)

## vertex arrays

proc newVertexArray*(buffers: seq[Buffer]): VertexArray =
    let handle = register(glCreateVertexArrays)
    result = VertexArray(handle: handle, buffers: buffers)

# shader attributes

proc inputPointer*(index, length, stride, offset: int, dataKind: DataKind, normalized: bool) =
    glVertexAttribPointer(index.uint32, length.int32, dataKind.asEnum, normalized, stride.int32, cast[pointer](offset))

proc configure*(buffer: Buffer, program: ShaderProgram, array: VertexArray) =
    for index in 0 ..< buffer.inputs.len:
        let input = buffer.inputs[index]

        let totalLength = buffer.inputs.mapIt(it.length).sum()

        let indicesBefore = buffer.inputs.indices.filterIt(it < index)
        let itemsBefore = indicesBefore.mapIt(buffer.inputs[it])
        let lengthBefore = itemsBefore.mapIt(it.length).sum()

        let stride = totalLength.int32 * buffer.dataKind.size
        let offset = lengthBefore * buffer.dataKind.size

        glBindAttribLocation(program.handle, index.uint32, input.name.cstring)
        inputPointer(index, input.length, stride, offset, buffer.dataKind, false)
        glEnableVertexAttribArray(index.uint32)

proc configurePointers*(array: VertexArray, program: ShaderProgram) =
    for buffer in array.buffers:
        buffer.configure(program, array)

# CPU-to-GPU communication

proc pack*[T](buffer: Buffer, data: seq[seq[T]]): seq[T] =
    for y in 0 ..< buffer.inputs[0].height:
        for index in 0 ..< buffer.inputs.len:
            let input = buffer.inputs[index]
            let subdata = data[index]

            for x in 0 ..< input.length:
                let pos = x + y * input.length
                let item = subdata[pos]

                result.add(item)

proc send*[T](buffer: Buffer, usage: DrawKind, data: seq[seq[T]]) =
    let packed = buffer.pack(data)

    glBufferData(buffer.kind.asEnum, packed.len * buffer.dataKind.size, unsafeAddr(packed), usage.asEnum)