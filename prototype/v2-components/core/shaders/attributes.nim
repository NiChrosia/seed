import programs

import opengl

proc newAttributeIndex*(program: ShaderProgram, name: string): uint32 =
    let signedIndex = glGetAttribLocation(program.handle, cstring(name))

    if signedIndex < 0:
        raise newException(ValueError, "Attribute '" & name & "' is not present within vertex shader!")

    return uint32(signedIndex)