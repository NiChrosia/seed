import base
import opengl

type
    Buffer* = object of GlObject

# internal

proc newBufferHandle*(): uint32 =
    glGenBuffers(1, addr result)

proc connectTo*(buffer: Buffer, target: GlEnum) =
    glBindBuffer(target, buffer.handle)

# usage

proc newBuffer*(): Buffer =
    result.handle = newBufferHandle()

proc allocate*(target: GlEnum, space: int32, usage: GlEnum) =
    glBufferData(target, space, nil, usage)

proc insert*(target: GlEnum, offset, size: int32, data: pointer) =
    glBufferSubData(target, offset, size, data)