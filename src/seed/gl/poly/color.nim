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
    # repr

    VertexRepr = object
        pos: Vector[2, float32]

    PropertiesRepr = object
        color: Vector[4, float32]
        model: SquareMatrix[4, float32]

    Category = ShapeCategory[VertexRepr, PropertiesRepr, InstancedDrawer]

    # properties

    Properties = object
        color: Vec4
        model: Mat4

proc newProperties(color: Vec4, model: Mat4): Properties =
    result.assign(color, model)

proc newDrawer(sides: int): InstancedDrawer =
    return newInstancedDrawer(GlTriangles, int32(3 * sides))

proc newCategory(program: ShaderProgram, drawer: InstancedDrawer): Category =
    return newShapeCategory[VertexRepr, PropertiesRepr, InstancedDrawer](program, drawer)

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

var categories: Table[int, Category]

proc colorPoly*(sides: int, color: Vec4, model: Mat4 = mat4()): ShapeHandle =
    var category = try:
        categories[sides]
    except KeyError:
        let drawer = newDrawer(sides)
        categories[sides] = newCategory(program, drawer)

        let vertices = newPolyVertices(sides)
        discard categories[sides].vertices.add(newBatch(vertices))

        categories[sides]

    let properties = newProperties(color, model)
    let indices = newPolyIndices(uint32(sides))

    result.offset = category.properties.add(newBatch(properties))
    discard category.indices.add(newBatch(indices))

    category.drawer.count += 1

proc drawColorPolygons*() =
    program.use()

    for category in categories.values:
        category.use()
        category.draw()