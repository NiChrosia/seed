import shaders, opengl, sugar

type
    ShaderUniform*[T] = object of RootObj
        name: string
        update*: (T) -> void

let
    updateFloat* = (location: int32, value: float32) => glUniform1f(location, value)
    updateTextureId* = (location: int32, value: int32) => glUniform1i(location, value)

proc newUniform*[T](program: ShaderProgram, name: string, rawUpdate: (int32, T) -> void): ShaderUniform[T] =
    let location = glGetUniformLocation(program.handle, name.cstring)
    let update = proc(value: T) =
        # implementing bind checks will require moving all types to a unified file, which is currently nonexistent
        #assert(ShaderProgram.isActive, "There is no shader program active, so a uniform cannot be updated!")

        rawUpdate(location, value)

    result = ShaderUniform[T](update: update)