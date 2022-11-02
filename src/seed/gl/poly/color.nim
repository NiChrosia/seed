import common, data
import ../buffers, ../attributes, ../macroutils
import ../shaders/[types, programs, uniforms, shaders]

import vmath, shady
import opengl

import std/[tables]

#[

this system is bad.
it includes a number of things it shouldn't, like the shaders,
and overall, it's an overabstraction

instead, there should simply be something to represent a draw call,
and the correlated buffers.

]#

# properties

type
    Properties = object
        color: Vec4
        model: Mat4

var vertexBuilder: AttributeBuilder
discard vertexBuilder
    .v(kFloat, 2, "pos")

var propertyBuilder: AttributeBuilder
discard propertyBuilder
    .v(kFloat, 4, "color", divisor = 1)
    .m(kFloat, 4, 4, "model", divisor = 1)

proc newProperties(color: Vec4, model: Mat4): Properties =
    result.assign(color, model)

# class

var
    program*: ShaderProgram

proc initializeColorPolygons*(vText, fText: string) =
    let vertexShader = initShader(sVertex, vText, true)
    let fragmentShader = initShader(sFragment, fText, true)

    program = initProgram([vertexShader, fragmentShader], true)

# usage

var categories: Table[int, InstanceCategory[Vec2, Properties]]

proc poly*(sides: int, color: Vec4, model: Mat4 = mat4()) =
    var category = try:
        categories[sides]
    except KeyError:
        var category = initInstCategory[Vec2, Properties](
            program, 
            vertexBuilder, propertyBuilder, 
            newPolyVertices(sides), newPolyIndices(uint32 sides)
        )

        categories[sides] = category

        category

    category.add(newProperties(color, model))

proc drawColorPolygons*() =
    program.use()

    for category in categories.values:
        category.draw()