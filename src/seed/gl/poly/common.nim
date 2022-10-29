import ../attributes, ../buffers
import ../shaders/[types]
import data

import vmath

import opengl

type
    ShapeCategory*[V, P] = ref object
        vertices*, properties*, indices*: Buffer
        configuration*: uint32

        perInstance, instances*: int32

## shape categories

proc newShapeCategory*[V, P, RealV](program: ShaderProgram, vertices: seq[RealV], indices: seq[uint32]): ShapeCategory[RealV, P] =
    # fields
    result = new(ShapeCategory[RealV, P])

    result.vertices = newBuffer(GlDynamicDraw)
    result.properties = newBuffer(GlDynamicDraw)
    result.indices = newBuffer(GlDynamicDraw)

    glGenVertexArrays(1, addr result.configuration)

    result.perInstance = int32(indices.len)

    # state
    glBindVertexArray(result.configuration)

    result.vertices.bindTo(GlArrayBuffer)
    declareAttributes(*program, V)

    result.properties.bindTo(GlArrayBuffer)
    declareAttributes(*program, P, true)

    result.indices.bindTo(GlElementArrayBuffer)

    # data
    discard result.vertices.add(newBatch(vertices))
    discard result.indices.add(newBatch(indices))

proc draw*(category: ShapeCategory) =
    glBindVertexArray(category.configuration)
    glDrawElementsInstanced(GL_TRIANGLES, category.perInstance, GL_UNSIGNED_INT, nil, category.instances)