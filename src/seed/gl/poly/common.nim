import ../attributes, ../buffers, ../macroutils
import ../shaders/[types]

import vmath

import opengl

type
    ShapeHandle* = object
        offset*: int32

    # drawers

    NormalDrawer* = object of RootObj
        mode: GlEnum
        vertices: int32

    InstancedDrawer* = object of NormalDrawer
        count*: int32

    # shapes

    ShapeCategory*[V, P, D] = ref object
        vertices*, properties*, indices*: Buffer
        configuration*: uint32

        drawer*: D

## drawers

# init

proc newDrawer*(mode: GLenum, vertices: int32): NormalDrawer =
    result.assign(mode, vertices)

proc newInstancedDrawer*(mode: GLenum, vertices: int32): InstancedDrawer =
    result.assign(mode, vertices)

# usage

proc draw*(drawer: NormalDrawer) =
    glDrawElements(drawer.mode, drawer.vertices, GL_UNSIGNED_INT, nil)

proc draw*(drawer: InstancedDrawer) =
    glDrawElementsInstanced(drawer.mode, drawer.vertices, GL_UNSIGNED_INT, nil, drawer.count)

## shape categories

proc newShapeCategory*[V, P, D](program: ShaderProgram, drawer: D): ShapeCategory[V, P, D] =
    result = new(ShapeCategory[V, P, D])

    result.drawer = drawer

    result.vertices = newBuffer(GlDynamicDraw)
    result.properties = newBuffer(GlDynamicDraw)
    result.indices = newBuffer(GlDynamicDraw)

    glGenVertexArrays(1, addr result.configuration)

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
    category.drawer.draw()