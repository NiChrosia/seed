import common
import ../base

import opengl

import std/[sugar]

type
    ShaderProgram* = object of GlObject
    LinkError* = object of Defect

# internal

proc newProgramHandle*(): uint32 =
    return glCreateProgram()

proc `[]`*(program: ShaderProgram, parameter: GlEnum): int32 =
    glGetProgramiv(program.handle, parameter, addr result)

proc log*(program: ShaderProgram): string =
    let length = program[GlInfoLogLength]
    # c-strings are null-terminated
    let logMemory = cast[cstring](alloc(length + 1))

    glGetProgramInfoLog(program.handle, length, nil, logMemory)
    result = $logMemory

    dealloc(logMemory)

let
    linkSuccess* = (program: ShaderProgram) => program[GlLinkStatus] == 1

# usage

proc newProgram*(): ShaderProgram =
    result.handle = newProgramHandle()

proc connectTo*(program: ShaderProgram, shaders: varargs[Shader]) =
    for shader in shaders:
        glAttachShader(program.handle, shader.handle)

proc connect*(program: ShaderProgram) =
    glUseProgram(program.handle)

proc link*(program: ShaderProgram) =
    glLinkProgram(program.handle)

    if not program.linkSuccess:
        var message = "Program linking failed!"
        message.add("\n")
        message.add(program.log)

        raise newException(LinkError, message)