import programs

import opengl

proc newAttributeIndex*(program: ShaderProgram, name: string): uint32 =
    let signedIndex = glGetAttribLocation(program.handle, cstring(name))

    return uint32(signedIndex)