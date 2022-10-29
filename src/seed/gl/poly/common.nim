import ../attributes, ../buffers, ../macroutils
import ../shaders/[types]

import vmath

import opengl

type
    Index* = uint32

    ShapeHandle* = object
        offset*: int32

    # drawers

    NormalDrawer* = object of RootObj
        mode, index: GlEnum
        vertices: int32

    InstancedDrawer* = object of NormalDrawer
        count*: int32

    # shapes

    ShapeCategory*[V, P, I, D] = ref object
        vertices*, properties*, indices*: Buffer
        configuration*: uint32

        drawer*: D

## drawers

# init

proc newDrawer*(mode, index: GlEnum, vertices: int32): NormalDrawer =
    result.assign(mode, index, vertices)

proc newInstancedDrawer*(mode, index: GlEnum, vertices: int32): InstancedDrawer =
    result.assign(mode, index, vertices)

# usage

proc draw*(drawer: NormalDrawer) =
    glDrawElements(drawer.mode, drawer.vertices, drawer.index, nil)

proc draw*(drawer: InstancedDrawer) =
    glDrawElementsInstanced(drawer.mode, drawer.vertices, drawer.index, nil, drawer.count)

## shape classes

# proc newShapeClass*(vertexSource, fragmentSource: string): ShapeClass =
#     let vertexShader = initShader(sVertex, vertexSource, true)
#     let fragmentShader = initShader(sFragment, fragmentSource, true)

#     result = new(ShapeClass)
#     result.program = initProgram([vertexShader, fragmentShader], true)

## shape categories

proc newShapeCategory*[V, P, I, D](program: ShaderProgram, drawer: D): ShapeCategory[V, P, I, D] =
    result = new(ShapeCategory[V, P, I, D])

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