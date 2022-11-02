import instcategories, data
import ../buffers, ../attributes, ../macroutils
import ../shaders/[types, programs, shaders]

import vmath, shady
import opengl

import std/[tables]

type
    Properties = object
        color: Vec4
        model: Mat4

# properties
proc newProperties(color: Vec4, model: Mat4): Properties =
    result.assign(color, model)

# variables & setup
var
    categories: Table[int, InstanceCategory[Vec2, Properties]]
    program: ShaderProgram

    vertexBuilder, propertyBuilder: AttributeBuilder

discard vertexBuilder
    .v(kFloat, 2, "pos")

discard propertyBuilder
    .v(kFloat, 4, "color", divisor = 1)
    .m(kFloat, 4, 4, "model", divisor = 1)

# api
proc minimumProgram*(): ShaderProgram =
    ## basic program required for this module

    proc processVertex(
        gl_Position: var Vec4, vColor: var Vec4, 
        pos: Vec2, color: Vec4, model: Mat4
    ) =
        gl_Position = model * vec4(vec3(pos, 0f), 1f)
        vColor = color

    proc processFragment(FragColor: var Vec4, vColor: Vec4) =
        FragColor = vColor

    var vertexShader = initShader(sVertex, toGLSL(processVertex), true)
    var fragmentShader = initShader(sFragment, toGLSL(processFragment), true)

    return initProgram([vertexShader, fragmentShader], true)

proc init*(program: ShaderProgram) =
    ## program needs a vertex shader with:
    ## - pos: vec2
    ## - color: vec4 (instanced [divisor of 1])
    ## - model: mat4 (instanced [1])
    
    poly.program = program

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

proc draw*() =
    program.use()

    for category in categories.values:
        category.draw()