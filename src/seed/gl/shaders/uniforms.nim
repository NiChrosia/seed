import opengl

import types

# shorthand
proc `@`*(name: string): UniformLocation =
    when not defined(release):
        var program: int32
        glGetIntegerv(GL_CURRENT_PROGRAM, addr program)

        let location = glGetUniformLocation(uint32(program), cstring(name))
        result = UniformLocation(location)
    else:
        raise newException(ReleasePerformanceDefect, "Querying the OpenGL state should not be done in release mode.")

proc `*`(location: UniformLocation): int32 =
    result = int32(location)

# initialization
proc locate*(program: ShaderProgram, name: string): UniformLocation =
    let location = glGetUniformLocation(*program, cstring(name))
    result = UniformLocation(location)

# updating
using
    l: UniformLocation

# - scalar
proc set*(l; value: int32) =
    glUniform1i(*l, value)

proc set*(l; value: float32) =
    glUniform1f(*l, value)

# - vector
proc set*(l; x, y: float32) =
    glUniform2f(*l, x, y)

proc set*(l; x, y, z: float32) =
    glUniform3f(*l, x, y, z)

proc set*(l; x, y, z, w: float32) =
    glUniform4f(*l, x, y, z, w)

# - matrix
proc set*(l; matrix: array[4, float32], transpose: bool) =
    glUniformMatrix2fv(*l, 1, transpose, unsafeAddr matrix[0])

proc set*(l; matrix: array[16, float32], transpose: bool) =
    glUniformMatrix4fv(*l, 1, transpose, unsafeAddr matrix[0])