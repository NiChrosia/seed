import common, data
import ../buffers, ../attributes, ../macroutils
import ../shaders/[types, programs, uniforms]

import vmath, shady
import opengl

import std/[tables]

# properties

type
    # repr

    VertexRepr = object
        pos: Vector[2, float32]

    PropertiesRepr = object
        color: Vector[4, float32]
        model: SquareMatrix[4, float32]

    Category = ShapeCategory[VertexRepr, PropertiesRepr, uint8, InstancedDrawer]

    # properties

    Properties = object
        color: Vec4
        model: Mat4

proc newProperties(color: Vec4, model: Mat4): Properties =
    result.assign(color, model)

proc newDrawer(sides: int): InstancedDrawer =
    return newInstancedDrawer(GlTriangles, GlUnsignedByte, int32(3 * sides))

proc newCategory(class: ShapeClass, drawer: InstancedDrawer): Category =
    return newShapeCategory[VertexRepr, PropertiesRepr, uint8, InstancedDrawer](class, drawer)

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
    class: ShapeClass

    program*: ShaderProgram
    view*, project*: UniformLocation

proc initializeColorPolygons*() =
    class = newShapeClass(toGLSL(processVertex), toGLSL(processFragment))
    program = class.program

    view = program.locate("view")
    project = program.locate("project")

# usage

var categories: Table[int, Category]

proc colorPoly*(sides: int, color: Vec4, model: Mat4 = mat4()): ShapeHandle =
    var category = try:
        categories[sides]
    except KeyError:
        let drawer = newDrawer(sides)
        categories[sides] = newCategory(class, drawer)

        let vertices = newPolyVertices(sides)
        discard categories[sides].vertices.add(newSeqBatch(vertices))

        categories[sides]

    let properties = newProperties(color, model)
    let indices = newPolyIndices(uint8(sides))

    result.offset = category.properties.add(newBatch(properties))
    discard category.indices.add(newSeqBatch(indices))

    category.drawer.count += 1

proc drawColorPolygons*() =
    program.use()

    for category in categories.values:
        category.use()
        category.draw()