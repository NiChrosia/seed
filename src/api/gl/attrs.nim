import opengl
import std/[strformat]

type
    Attribute = object
        location: GLuint
        columns, rows: GLuint
        kind: GLenum

    BufferAttributes = object of RootObj
        buffer: GLuint
        stride: GLuint
        values: seq[Attribute]

    SequentialBufferAttributes = object of BufferAttributes
        index: GLuint

    NamedBufferAttributes = object of BufferAttributes
        program: GLuint

    Attributes = object
        vao: GLuint
        bufferAttributes: seq[BufferAttributes]

proc attributeKindFor(nimType: typedesc): GLenum =
    return case $nimType
    of "float":
        cGL_FLOAT
    of "int":
        cGL_INT
    else:
        raise Exception.newException(fmt"Unimplemented attribute kind '{$nimType}'!")

proc attributeSizeOf(kind: GLenum): GLuint =
    return case kind
    of cGL_FLOAT:
        4
    of cGL_INT:
        4
    else:
        raise Exception.newException(fmt"Unimplemented attribute size '{$GLuint(kind)}'!")

proc attributeFormat(vao: GLuint, location: GLuint, columns, rows: GLuint, kind: GLenum, memoryOffset: GLuint) =
    template format(locationOffset, sizeOffset: GLuint) =
        if kind == cGL_INT:
            let newLocation = location + locationOffset
            let newOffset = memoryOffset + sizeOffset

            glVertexArrayAttribIFormat(vao, newLocation, GLint(columns), kind, newOffset)
        elif kind == cGL_FLOAT:
            let newLocation = location + locationOffset
            let newOffset = memoryOffset + sizeOffset

            glVertexArrayAttribFormat(vao, newLocation, GLint(columns), kind, false, newOffset)
        else:
            raise Exception.newException(fmt"Unrecognized attribute kind '{GLuint(kind)}'!")

    for offset in 0 ..< rows:
        format(GLuint(offset), GLuint(offset) * attributeSizeOf(kind) * columns)

# buffer attributes
# - sequential
proc mat*(attributes: SequentialBufferAttributes, nimType: typedesc, columns, rows: GLuint): SequentialBufferAttributes =
    result = attributes

    let attribute = Attribute(
        location: result.index,
        columns: columns,
        rows: rows,
        kind: attributeKindFor(nimType)
    )

    result.values.add(attribute)

    result.index += 1
    result.stride += attributeSizeOf(attribute.kind) * columns * rows

proc vec*(attributes: SequentialBufferAttributes, nimType: typedesc, components: GLuint): SequentialBufferAttributes =
    return attributes.mat(nimType, components, 1)

proc sca*(attributes: SequentialBufferAttributes, nimType: typedesc): SequentialBufferAttributes =
    return attributes.vec(nimType, 1)

proc sequential*(buffer: GLuint): SequentialBufferAttributes =
    return SequentialBufferAttributes(buffer: buffer)

proc build*(attributes: SequentialBufferAttributes): BufferAttributes =
    return BufferAttributes(
        buffer: attributes.buffer,
        stride: attributes.stride,
        values: attributes.values,
    )

# - named attributes
proc named*(program, buffer: GLuint): NamedBufferAttributes =
    return NamedBufferAttributes(program: program, buffer: buffer)

proc mat*(attributes: NamedBufferAttributes, name: string, nimType: typedesc, columns, rows: GLuint): NamedBufferAttributes =
    result = attributes

    let attribute = Attribute(
        location: GLuint(glGetAttribLocation(attributes.program, cstring(name))),
        columns: columns,
        rows: rows,
        kind: attributeKindFor(nimType)
    )

    result.values.add(attribute)
    result.stride += attributeSizeOf(attribute.kind) * columns * rows

proc vec*(attributes: NamedBufferAttributes, name: string, nimType: typedesc, components: GLuint): NamedBufferAttributes =
    return attributes.mat(name, nimType, components, 1)

proc sca*(attributes: NamedBufferAttributes, name: string, nimType: typedesc): NamedBufferAttributes =
    return attributes.vec(name, nimType, 1)

proc build*(attributes: NamedBufferAttributes): BufferAttributes =
    return BufferAttributes(
        buffer: attributes.buffer,
        stride: attributes.stride,
        values: attributes.values,
    )

# attributes
proc attributes*(vao: GLuint): Attributes =
    return Attributes(vao: vao)

proc buffer*(attributes: Attributes, bufferAttributes: BufferAttributes): Attributes =
    result = attributes
    result.bufferAttributes.add(bufferAttributes)

proc build*(attributes: Attributes) =
    let vao = attributes.vao

    for bufferIndex in 0 .. attributes.bufferAttributes.high:
        let bufferAttributes = attributes.bufferAttributes[bufferIndex]

        let index = GLuint(bufferIndex)
        let buffer = bufferAttributes.buffer
        let bufferOffset = 0
        let stride = bufferAttributes.stride

        glVertexArrayVertexBuffer(vao, index, buffer, bufferOffset, GLsizei(stride))

        var offset: GLuint = 0

        for attribute in bufferAttributes.values:
            glEnableVertexArrayAttrib(vao, attribute.location)
            attributeFormat(vao, attribute.location, attribute.columns, attribute.rows, attribute.kind, offset)
            glVertexArrayAttribBinding(vao, attribute.location, index)

            offset += attributeSizeOf(attribute.kind) * attribute.columns * attribute.rows
