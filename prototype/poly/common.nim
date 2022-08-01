import ../attributes, ../buffers, ../macroutils
import ../../src/seed/video/backends/gl/shaders

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

    ShapeClass* = ref object
        program*: ShaderProgram

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

proc newShapeClass*(vertexSource, fragmentSource: string): ShapeClass =
    let vertexShader = newShader(GlVertexShader, vertexSource)
    let fragmentShader = newShader(GlFragmentShader, fragmentSource)

    result = new(ShapeClass)

    result.program = newProgram()
    result.program.shaders = (vertexShader, fragmentShader)
    result.program.link()

## shape categories

proc newShapeCategory*[V, P, I, D](class: ShapeClass, drawer: D): ShapeCategory[V, P, I, D] =
    result = new(ShapeCategory[V, P, I, D])

    result.drawer = drawer

    result.vertices = newBuffer(GlDynamicDraw)
    result.properties = newBuffer(GlDynamicDraw)
    result.indices = newBuffer(GlDynamicDraw)

    glGenVertexArrays(1, addr result.configuration)

    # configuration

    glBindVertexArray(result.configuration)

    result.vertices.bindTo(GlArrayBuffer)
    declareAttributes(class.program.handle, V)

    result.properties.bindTo(GlArrayBuffer)
    declareAttributes(class.program.handle, P, true)

    result.indices.bindTo(GlElementArrayBuffer)

proc use*(category: ShapeCategory) =
    glBindVertexArray(category.configuration)

proc draw*(category: ShapeCategory) =
    category.drawer.draw()

## general poly functions

proc newPolyVertices*(sides: int): seq[Vec2] =
    let increment = (360f / float32(sides)).toRadians()

    # add a center vertex for indices
    result.add(vec2(0f, 0f))

    for index in 1 .. sides:
        let angle = increment * float32(index)

        let x = cos(angle)
        let y = sin(angle)

        let vertex = vec2(x, y)
        result.add(vertex)

# generic number parameter to allow varying precision,
# for the sake of memory efficiency
proc newPolyIndices*[I](sides: I): seq[I] =
    let center: I = 0
    let one = I(1)

    for index in one .. sides:
        var nextIndex = index + one
        if nextIndex > sides:
            nextIndex = one

        result.add(center)
        result.add(index)
        result.add(nextIndex)