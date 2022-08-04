import base

import opengl

type
    VertexArray* = object of GlObject

# internal

proc newVertexArrayHandle*(): uint32 =
    glGenVertexArrays(1, addr result)

proc connect*(array: VertexArray) =
    glBindVertexArray(array.handle)

proc dataKindOf*[T](kind: typedesc[T]): GlEnum =
    return case $kind
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

# usage

proc newVertexArray*(): VertexArray =
    result.handle = newVertexArrayHandle()

proc setVector*[T](
    index: uint32, kind: typedesc[T],
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
    
    let dataKind = dataKindOf(kind)

    glVertexAttribPointer(index, height, dataKind, normalized, stride, cast[pointer](offset))
    glEnableVertexAttribArray(index)

proc setScalar*[T](
    index: uint32, kind: typedesc[T],
    offset: int32,
    stride: int32,
    normalized: bool = false
) =
    ## A simple convenience function for scalar attributes.

    setVector(index, kind, offset, 1, stride, normalized)

proc setMatrix*[T](
    baseIndex: uint32, kind: typedesc[T],
    baseOffset, width, height: int32,
    stride: int32,
    normalized: bool = false
) =
    ## Matrices have special attribute behavior - as
    ## an attribute in GLSL is defined to only have
    ## a height of 1-4, matrices were correspondingly
    ## defined to be multiple attributes with offset
    ## memory values & indices.
    
    let memorySize = int32(sizeof(kind))

    for shift in 0 ..< width:
        let index = baseIndex + shift
        let offset = baseOffset + (shift * memorySize)

        setVector(index, offset, height, kind, stride, normalized)

proc setDivisor*(index: uint32, divisor: uint32) =
    glVertexAttribDivisor(index, divisor)