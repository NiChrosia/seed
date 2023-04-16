import opengl

import types, queries/shaders

# compilation
proc define*(shader: Shader, source: string) =
    ## Sets, or defines, the shader source. High-level
    ## equivalent of glShaderSource.

    let asArray = [source]
    let asCArray = allocCStringArray(asArray)

    glShaderSource(*shader, 1, asCArray, nil)

    deallocCStringArray(asCArray)

proc compile*(shader: Shader) =
    glCompileShader(*shader)

proc check*(shader: Shader) =
    ## Checks whether the shader compiled successfully,
    ## and if not, raises an exception with the log.

    if not shader.didCompile:
        raise newException(CompilationFailure, shader.log)

# lifetime
proc delete*(shader: Shader) =
    glDeleteShader(*shader)

proc initShader*(kind: ShaderKind): Shader =
    result = Shader(glCreateShader(kind.GLenum))

proc initShader*(kind: ShaderKind, source: string, check: bool): Shader =
    ## More concise shader initialization.

    result = initShader(kind)
    result.define(source)
    result.compile()

    if check:
        result.check()