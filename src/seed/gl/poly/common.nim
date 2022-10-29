import ../attributes, ../buffers, ../macroutils
import ../shaders/[types]

import vmath

import opengl

type
    ShapeHandle* = object
        offset*: int32

    # shapes

    ShapeCategory*[V, P] = ref object
        vertices*, properties*, indices*: Buffer
        configuration*: uint32

        perInstance, instances*: int32

## drawers

# init

# proc newDrawer*(mode: GLenum, vertices: int32): NormalDrawer =
#     result.assign(mode, vertices)

# proc newInstancedDrawer*(mode: GLenum, vertices: int32): InstancedDrawer =
#     result.assign(mode, vertices)

# # usage

# proc draw*(drawer: NormalDrawer) =
#     glDrawElements(drawer.mode, drawer.vertices, GL_UNSIGNED_INT, nil)

# proc draw*(drawer: InstancedDrawer) =
#     glDrawElementsInstanced(drawer.mode, drawer.vertices, GL_UNSIGNED_INT, nil, drawer.count)

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

proc use*(category: ShapeCategory) =
    glBindVertexArray(category.configuration)

proc draw*(category: ShapeCategory) =
    glDrawElementsInstanced(GL_TRIANGLES, category.perInstance, GL_UNSIGNED_INT, nil, category.instances)