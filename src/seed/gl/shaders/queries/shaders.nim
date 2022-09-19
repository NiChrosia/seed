import opengl

import ../types

# internal
proc query(shader: Shader, query: Glenum): int32 =
    glGetShaderiv(*shader, query, addr result)

# direct properties
proc kind*(shader: Shader): ShaderKind =
    return ShaderKind(shader.query(GL_SHADER_TYPE))

# state
proc didCompile*(shader: Shader): bool =
    ## Whether this shader compiled successfully.
    
    return bool(shader.query(GL_COMPILE_STATUS))

# strings
proc logLength*(shader: Shader): int32 =
    return shader.query(GL_INFO_LOG_LENGTH)

proc log*(shader: Shader): string =
    let length = shader.logLength
    var buffer = cast[cstring](alloc(length + 1))

    glGetShaderInfoLog(*shader, length, nil, buffer)

    result = $buffer
    dealloc(buffer)