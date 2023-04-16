import opengl

import ../types

type
    ## entirely for shorthand use
    Program = ShaderProgram

# internal
proc query(program: Program, query: Glenum): int32 =
    glGetProgramiv(*program, query, addr result)

# state
proc didLink*(program: Program): bool =
    result = bool(program.query(GL_LINK_STATUS))

# strings
proc logLength*(program: Program): int32 =
    result = program.query(GL_INFO_LOG_LENGTH)

proc log*(program: Program): string =
    let length = program.logLength
    var buffer = cast[cstring](alloc(length + 1))

    glGetProgramInfoLog(*program, length, nil, buffer)

    result = $buffer
    dealloc(buffer)