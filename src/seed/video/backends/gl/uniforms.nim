import shaders, binding/activity, opengl, vmath, std/[sugar]

type
    ShaderUniform*[T] = object of RootObj
        name: string
        update*: (T) -> void

let
    updateFloat* = (location: int32, value: float32) => glUniform1f(location, value)
    updateTextureId* = (location: int32, value: int32) => glUniform1i(location, value)

    updateVec2* = (location: int32, value: Vec2) => glUniform2f(location, value.x, value.y)
    updateVec3* = (location: int32, value: Vec3) => glUniform3f(location, value.x, value.y, value.z)

    updateMatrix* = (location: int32, value: Mat4) => glUniformMatrix4fv(location, 1, false, unsafeAddr(value[0, 0]))

proc newUniform*[T](program: ShaderProgram, name: string, rawUpdate: (int32, T) -> void): ShaderUniform[T] =
    let location = glGetUniformLocation(program.handle, name.cstring)
    let update = proc(value: T) =
        assert(ShaderProgram.active, "There is no shader program active, so a uniform cannot be updated!")

        rawUpdate(location, value)

    result = ShaderUniform[T](update: update)