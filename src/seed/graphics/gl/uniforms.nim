import binding, shaders, opengl, sugar

type
    UniformKind*[T] = object
        update: proc(location: int32, value: T)

    Uniform*[T] = object of RootObj
        update*: proc(value: T)

let
    floatUniform* = UniformKind[float32](update: (location: int32, value: float32) => glUniform1f(location, value))

proc newUniform*[T](program: ShaderProgram, name: string, kind: UniformKind[T]): Uniform[T] =
    let location = glGetUniformLocation(program.handle, name.cstring)
    let update = proc(value: T) =
        assert(ShaderProgram.isActive, "There is no shader program active, so a uniform cannot be updated!")

        kind.update(location, value)

    result = Uniform[T](update: update)