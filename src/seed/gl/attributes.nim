import opengl

type
    Attribute* = object
        # GLSL kind
        kind*: GLenum
        # vector component count
        components*: int32
        # shader input name
        name*: string
        # used for instancing
        divisor*: uint32

        # memory size of this attribute
        size*: int32
        # used to specify index offset for matrices
        offset*: uint32

    AttributeBuilder* = object
        array*, buffer*, program*: uint32
        values*: seq[Attribute]

        stride*: int32

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

# state variables
proc a*(b: var AttributeBuilder, handle: uint32): var AttributeBuilder =
    b.array = handle

    return b

proc b*(b: var AttributeBuilder, handle: uint32): var AttributeBuilder =
    b.buffer = handle

    return b

proc p*(b: var AttributeBuilder, handle: uint32): var AttributeBuilder =
    b.program = handle

    return b

# attributes
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

# this implementation is (kinda) stateless, but
# if you want to make it stateful or whatever
# other change, just make a new build() function,
# as all the fields and procs are exported
proc build*(b: AttributeBuilder) =
    # probably incorrect usage of runnableExamples, but 
    # it's an example nonetheless
    runnableExamples:
        var b: AttributeBuilder
        b
            # a and p are intentionally separate functions from
            # the constructor so that you can pass solely attribute
            # configuration without an array or program

            .a(0) # some vertex array
            .p(0) # some program

            .s(kFloat, "") # can't think of a typical scalar attribute, but it's an available option
            .v(kFloat, 3, "position") # vectors
            .v(kFloat, 4, "color")
            .m(kFloat, 4, 4, "model") # matrices

            .build()

    when not defined(release):
        if b.array == 0:
            raise Exception.newException("cannot build with invalid array!")

        if b.buffer == 0:
            raise Exception.newException("cannot build with invalid buffer!")

        if not glIsProgram(b.program):
            raise Exception.newException("cannot build with invalid program!")

    glBindVertexArray(b.array)
    glBindBuffer(GL_ARRAY_BUFFER, b.buffer)

    var aOffset: int32

    for a in b.values:
        let index = uint32(glGetAttribLocation(b.program, cstring(a.name))) + a.offset

        when not defined(release):
            if int32(index) - int32(a.offset) == -1:
                assert false, "attribute '" & a.name & "' not found in program!"

        glEnableVertexAttribArray(index)
        glVertexAttribPointer(index, a.components, a.kind, false, b.stride, cast[pointer](aOffset))

        glVertexAttribDivisor(index, a.divisor)

        aOffset += a.size