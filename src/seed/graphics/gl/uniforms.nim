import shaders, opengl, sugar

type
    UniformKind*[T] = object
        update: proc(location: int32, value: T)

    ShaderUniform*[T] = object of RootObj
        update*: proc(value: T)

let
    floatUniform* = UniformKind[float32](update: (location: int32, value: float32) => glUniform1f(location, value))
    samplerUniform* = UniformKind[int32](update: (location: int32, value: int32) => glUniform1i(location, value))

proc newUniform*[T](program: ShaderProgram, name: string, kind: UniformKind[T]): ShaderUniform[T] =
    let location = glGetUniformLocation(program.handle, name.cstring)
    let update = proc(value: T) =
        # implementing bind checks will require moving all types to a unified file, which is currently nonexistent
        #assert(ShaderProgram.isActive, "There is no shader program active, so a uniform cannot be updated!")

        kind.update(location, value)

    result = ShaderUniform[T](update: update)