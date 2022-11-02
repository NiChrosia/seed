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

# shaders

proc processVertex(
    gl_Position: var Vec4, vColor: var Vec4, 
    pos: Vec2, color: Vec4, model: Mat4,
    view: Uniform[Mat4], project: Uniform[Mat4]
) =
    gl_Position = project * view * model * vec4(vec3(pos, 0f), 1f)
    vColor = color

proc processFragment(FragColor: var Vec4, vColor: Vec4) =
    FragColor = vColor

# class

var
    program*: ShaderProgram
    view*, project*: UniformLocation

proc initializeColorPolygons*() =
    let vertexShader = initShader(sVertex, toGLSL(processVertex), true)
    let fragmentShader = initShader(sFragment, toGLSL(processFragment), true)

    program = initProgram([vertexShader, fragmentShader], true)

    view = program.locate("view")
    project = program.locate("project")

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