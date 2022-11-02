import instcategories, data
import ../buffers, ../attributes, ../macroutils
import ../shaders/[types, programs]

import vmath
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