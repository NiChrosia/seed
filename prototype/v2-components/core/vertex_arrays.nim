import base

import opengl

type
    VertexArray* = object of GlObject

# internal

proc newVertexArrayHandle*(): uint32 =
    glGenVertexArrays(1, addr result)

proc connect*(array: VertexArray) =
    glBindVertexArray(array.handle)

proc dataKindOf*(kind: string): GlEnum =
    return case kind
    # normal integers
    of "int8":
        cGlByte
    of "int16":
        cGlShort
    of "int32":
        cGlInt
    # unsigned integers
    of "uint8":
        cGlUnsignedByte
    of "uint16":
        cGlUnsignedShort
    of "uint32":
        GlUnsignedInt
    # floats
    of "float32":
        cGlFloat
    else:
        raise newException(ValueError, "Unrecognized data kind '" & $kind & "'!")

proc dataSizeOf*(kind: GlEnum): int32 =
    let normalSize = case kind
    of cGlByte:
        sizeof(int8)
    of cGlShort:
        sizeof(int16)
    of cGlInt:
        sizeof(int32)
    of cGlUnsignedByte:
        sizeof(uint8)
    of cGlUnsignedShort:
        sizeof(uint16)
    of GlUnsignedInt:
        sizeof(uint32)
    of cGlFloat:
        sizeof(float32)
    else:
        raise newException(ValueError, "Unrecognized data kind!")

    return int32(normalSize)

proc dataKindOf*[T](kind: typedesc[T]): GlEnum =
    return dataKindOf($kind)

# usage

proc newVertexArray*(): VertexArray =
    result.handle = newVertexArrayHandle()

proc setVector*(
    index: uint32, kind: GlEnum,
    offset, height: int32,
    stride: int32,
    normalized: bool = false
) =
    ## Explanation of parameters:
    ##   - index: Index of this attribute, can be bound or retrieved
    ##   using shader program functions.
    ##   - offset: The memory offset of the buffer data for this attribute.
    ##   - size: If height > 1, the height of this vector; otherwise, 
    ##   this simply means this is a scalar value.
    ##   - kind: the data kind used by GL to determine the memory size
    ##   - stride: the memory stride between each item in buffer data.
    ##   - normalized: "whether fixed-point data values should be
    ##   normalized"

    echo "setVector(index: ", index, ", offset: ", offset, ", height: ", height, ", stride: ", stride, ", normalized: ", normalized, ")"

    glEnableVertexAttribArray(index)
    glVertexAttribPointer(index, height, kind, normalized, stride, cast[pointer](offset))

proc setScalar*(
    index: uint32, kind: GlEnum,
    offset: int32,
    stride: int32,
    normalized: bool = false
) =
    ## A simple convenience function for scalar attributes.

    setVector(index, kind, offset, 1, stride, normalized)

proc setMatrix*(
    baseIndex: uint32, kind: GlEnum,
    baseOffset, width, height: int32,
    stride: int32,
    normalized: bool = false
) =
    ## Matrices have special attribute behavior - as
    ## an attribute in GLSL is defined to only have
    ## a height of 1-4, matrices were correspondingly
    ## defined to be multiple attributes with offset
    ## memory values & indices.
    
    let memorySize = dataSizeOf(kind)

    for shift in 0 ..< width:
        let index = baseIndex + uint32(shift)
        let offset = baseOffset + (shift * height * memorySize)

        setVector(index, kind, offset, height, stride, normalized)

proc setDivisor*(index: uint32, divisor: uint32) =
    glVertexAttribDivisor(index, divisor)