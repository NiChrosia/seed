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

proc allocateWith*(target: GlEnum, size: int, data: pointer, usage: GlEnum) =
    glBufferData(target, int32(size), data, usage)

proc allocate*(target: GlEnum, space: int, usage: GlEnum) =
    target.allocateWith(space, nil, usage)

proc insert*(target: GlEnum, offset, size: int32, data: pointer) =
    glBufferSubData(target, offset, size, data)

# convenience

proc allocateWith*[T](target: GlEnum, data: openArray[T], usage: GlEnum) =
    let size = data.len() * sizeof(T)

    target.allocateWith(size, unsafeAddr data[0], usage)

proc allocateWith*[T: object](target: GlEnum, data: T, usage: GlEnum) =
    let size = sizeof(T)

    target.allocateWith(size, unsafeAddr data, usage)