import opengl
import ../gl/buffers

type
    Ssbo* = object
        buffer*: Buffer
        binding*: GLuint

proc init*(_: typedesc[Ssbo], usage: GLenum, binding: GLuint): Ssbo =
    result.buffer = Buffer.init(usage)
    result.binding = binding

    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, binding, result.buffer.handle)

proc attach*(buffer: Ssbo, program: GLuint, name: string) =
    let index = glGetProgramResourceIndex(program, GL_SHADER_STORAGE_BLOCK, cstring(name))
    glShaderStorageBlockBinding(program, index, buffer.binding)

proc update*(buffer: Ssbo, x, width: GLintptr, data: pointer) =
    glNamedBufferSubData(buffer.buffer.handle, x, width, data)
