import ../base

import opengl

import std/[sugar]

type
    Shader* = object of GlObject
    CompileError* = object of Defect

# internal

proc newShaderHandle*(kind: GlEnum): uint32 =
    return glCreateShader(kind)

proc `[]`*(shader: Shader, parameter: GlEnum): int32 =
    glGetShaderiv(shader.handle, parameter, addr result)

proc log*(shader: Shader): string =
    let length = shader[GlInfoLogLength]
    # c-strings are null-terminated
    let logMemory = cast[cstring](alloc(length + 1))

    glGetShaderInfoLog(shader.handle, length, nil, logMemory)
    result = $logMemory

    dealloc(logMemory)

let
    compileSuccess* = (shader: Shader) => shader[GlCompileStatus] == 1

# usage

proc newShader*(kind: GlEnum): Shader =
    result.handle = newShaderHandle(kind)

proc compile*(shader: Shader, source: string) =
    ## By default sets the source and
    ## checks for compilation errors.
    
    # set source

    let sources = [source]
    let cSources = allocCStringArray(sources)

    glShaderSource(shader.handle, 1, cSources, nil)

    dealloc(cSources)

    # compile

    glCompileShader(shader.handle)

    if not shader.compileSuccess:
        var message = "Shader compilation failed!"
        message.add("\n")
        message.add(shader.log)

        raise newException(CompileError, message)