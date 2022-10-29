import ../attributes, ../buffers
import ../shaders/[types]

import vmath

import opengl

type
    ShapeCategory*[V, P] = ref object
        vertices*, properties*, indices*: Buffer
        configuration*: uint32

        perInstance, instances*: int32

## shape categories

proc newShapeCategory*[V, P](program: ShaderProgram, perInstance: int32): ShapeCategory[V, P] =
    result = new(ShapeCategory[V, P])

    result.vertices = newBuffer(GlDynamicDraw)
    result.properties = newBuffer(GlDynamicDraw)
    result.indices = newBuffer(GlDynamicDraw)

    glGenVertexArrays(1, addr result.configuration)

    result.perInstance = perInstance

    # configuration

    glBindVertexArray(result.configuration)

    result.vertices.bindTo(GlArrayBuffer)
    declareAttributes(*program, V)

    result.properties.bindTo(GlArrayBuffer)
    declareAttributes(*program, P, true)

    result.indices.bindTo(GlElementArrayBuffer)

proc draw*(category: ShapeCategory) =
    glBindVertexArray(category.configuration)
    glDrawElementsInstanced(GL_TRIANGLES, category.perInstance, GL_UNSIGNED_INT, nil, category.instances)