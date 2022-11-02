import opengl

type
    Attribute* = object
        # GLSL kind
        kind: GLenum
        # vector component count
        components: int32
        # shader input name
        name: string
        # used for instancing
        divisor: uint32

        # memory size of this attribute
        size: int32
        # used to specify index offset for matrices
        offset: uint32

    AttributeBuilder* = object
        array, program: uint32
        values: seq[Attribute]

        stride: int32

# attributes
const
    kByte* = cGL_BYTE
    kUByte* = GL_UNSIGNED_BYTE
    kShort* = cGL_SHORT
    kUShort* = GL_UNSIGNED_SHORT
    kInt* = cGL_INT
    kUInt* = GL_UNSIGNED_INT
    kFloat* = cGL_FLOAT
    kDouble* = cGL_DOUBLE

proc size(kind: GLenum): int32 =
    case kind
    of cGL_BYTE, GL_UNSIGNED_BYTE:
        return 1
    of cGL_SHORT, GL_UNSIGNED_SHORT:
        return 2
    of cGL_INT, GL_UNSIGNED_INT, cGL_FLOAT:
        return 4
    of cGL_DOUBLE:
        return 8
    else:
        assert false, "unrecognized kind!"

# builders
proc a*(b: var AttributeBuilder, handle: uint32): var AttributeBuilder =
    b.array = handle

    return b

proc p*(b: var AttributeBuilder, handle: uint32): var AttributeBuilder =
    b.program = handle

    return b

proc v*(b: var AttributeBuilder, kind: GLenum, components: range[1..4], name: string, divisor, offset: uint32 = 0): var AttributeBuilder =
    var a = Attribute(kind: kind, components: components, name: name, divisor: divisor, offset: offset)
    a.size = a.kind.size * a.components

    b.values.add(a)
    b.stride += a.size

    return b

proc s*(b: var AttributeBuilder, kind: GLenum, name: string, divisor: uint32 = 0): var AttributeBuilder =
    return b.v(kind, 1, name, divisor = divisor)

proc m*(b: var AttributeBuilder, kind: GLenum, w, h: range[1..4], name: string, divisor: uint32 = 0): var AttributeBuilder =
    for o in 0 ..< h:
        discard b.v(kind, w, name, divisor = divisor, offset = uint32(o))

    return b

proc build*(b: AttributeBuilder) =
    var aOffset: int32

    for a in b.values:
        let index = uint32(glGetAttribLocation(b.program, cstring(a.name))) + a.offset

        glEnableVertexAttribArray(index)
        glVertexAttribPointer(index, a.components, a.kind, false, b.stride, cast[pointer](aOffset))

        glVertexAttribDivisor(index, a.divisor)

        aOffset += a.size