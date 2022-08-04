import programs

import vmath
import opengl

import std/[sugar]

type
    Uniform*[T] = object
        index*: int32
        update: (T) -> void

# internal

proc newUniformIndex*(program: ShaderProgram, name: string): int32 =
    return glGetUniformLocation(program.handle, cstring(name))

proc updateFunction*[T](index: int32): (T) -> void =
    return case T
    of float32:
        (value: float32) => glUniform1f(index, value)
    of int32:
        (value: int32) => glUniform1i(index, value)
    of Vec2:
        (value: Vec2) => glUniform2f(index, value.x, value.y)
    of Vec3:
        (value: Vec3) => glUniform3f(index, value.x, value.y, value.z)
    of Vec4:
        (value: Vec4) => glUniform4f(index, value.w, value.y, value.z, value.w)
    of Mat4:
        (value: Mat4) => glUniformMatrix4fv(index, 1, false, unsafeAddr value[0, 0])

# usage

proc newUniform*[T](program: ShaderProgram, name: string): Uniform[T] =
    result.index = newUniformIndex(program, name)
    result.update = updateFunction(result.index)