import opengl
import ../gl/buffers

type
    UniformBuffer* = object
        buffer*: Buffer
        binding*: GLuint

proc init*(_: typedesc[UniformBuffer], usage: GLenum, binding: GLuint): UniformBuffer =
    result.buffer = Buffer.init(usage)
    result.binding = binding

    glBindBufferBase(GL_UNIFORM_BUFFER, binding, result.buffer.handle)

proc attach*(buffer: UniformBuffer, program: GLuint, name: string) =
    let index = glGetUniformBlockIndex(program, cstring(name))
    glUniformBlockBinding(program, index, buffer.binding)

proc update*(buffer: UniformBuffer, x, width: GLintptr, data: pointer) =
    glNamedBufferSubData(buffer.buffer.handle, x, width, data)
