import vmath
import opengl

proc setMat4*(program: GLuint, name: string, mat: Mat4) =
    glProgramUniformMatrix4fv(program, glGetUniformLocation(program, cstring(name)), 1, false, unsafeAddr mat[0, 0])
