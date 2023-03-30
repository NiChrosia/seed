import opengl

type
    ShaderCompileError = object of ValueError
    ProgramLinkError = object of ValueError

proc compile*(shader: GLuint, source: string) =
    proc q(shader: GLuint, param: GLenum): int32 =
        glGetShaderiv(shader, param, addr result)

    block define:
        let asArray = [source]
        let asCArray = allocCStringArray(asArray)

        glShaderSource(shader, 1, asCArray, nil)

        deallocCStringArray(asCArray)

    # compile
    glCompileShader(shader)

    # check
    if shader.q(GL_COMPILE_STATUS) == 0:
        let length = shader.q(GL_INFO_LOG_LENGTH)
        var buffer = cast[cstring](alloc(length + 1))

        glGetShaderInfoLog(shader, length, nil, buffer)

        let log = $buffer
        dealloc(buffer)

        raise ShaderCompileError.newException("Compilation failed with error: " & log)

proc link*(program: GLuint) =
    proc q(program: GLuint, param: GLenum): int32 =
        glGetProgramiv(program, param, addr result)

    # link
    glLinkProgram(program)

    # check
    if program.q(GL_LINK_STATUS) == 0:
        let length = program.q(GL_INFO_LOG_LENGTH)
        var buffer = cast[cstring](alloc(length + 1))

        glGetProgramInfoLog(program, length, nil, buffer)

        let log = $buffer
        dealloc(buffer)

        raise ProgramLinkError.newException("Linking failed with error: " & log)
