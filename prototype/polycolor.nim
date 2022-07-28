import sections, attributes
import ../src/seed/video/backends/gl

import opengl
import vmath, shady

import std/[tables, strformat]

# utility
type
    ShapeBuffers = ref object
        vertices, properties, indices: sections.Buffer

    ShapeSections = ref object
        sides, count: int32
        vertices, properties, indices: Section

    WrappedShape*[S] = object
        shape: S
        offset: int32

# for processing
type
    PolyVertex = object
        pos: Vector[2, float32]

    PolyRepr = object
        color: Vector[4, float32]
        model: SquareMatrix[4, float32]

    Poly = object
        color: Vec4
        model: Mat4

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

# utility

proc newShapeBuffers(usage: GlEnum): ShapeBuffers =
    result = new(ShapeBuffers)

    result.vertices = newBuffer(GlDynamicDraw)
    result.properties = newBuffer(GlDynamicDraw)
    result.indices = newBuffer(GlDynamicDraw)

proc newShapeSections(buffers: var ShapeBuffers, sides: int32): ShapeSections =
    result = new(ShapeSections)

    result.sides = sides

    result.vertices = buffers.vertices.newSection()
    result.properties = buffers.properties.newSection()
    result.indices = buffers.indices.newSection()

# end utility

var
    vertexShader, fragmentShader: Shader
    program*: ShaderProgram

    view*, project*: ShaderUniform[Mat4]

    buffers: ShapeBuffers

    configuration: uint32

proc initialize*() =
    # shaders
    vertexShader = newShader(GlVertexShader, toGLSL(processVertex))
    fragmentShader = newShader(GlFragmentShader, toGLSL(processFragment))

    program = newProgram()

    program.shaders = (vertexShader, fragmentShader)
    program.link()

    view = program.newUniform[:Mat4]("view", updateMatrix)
    project = program.newUniform[:Mat4]("project", updateMatrix)

    # buffers
    buffers = newShapeBuffers(GlDynamicDraw)

    # vertex array
    glGenVertexArrays(1, addr configuration)

proc configure*() =
    var firstTime {.global.} = true

    glBindVertexArray(configuration)

    if firstTime:
        glBindBuffer(GlArrayBuffer, buffers.vertices.handle)
        declareAttributes(program.handle, PolyVertex)

        glBindBuffer(GlArrayBuffer, buffers.properties.handle)
        declareAttributes(program.handle, PolyRepr, true)

        glBindBuffer(GlElementArrayBuffer, buffers.indices.handle)
    else:
        glBindBuffer(GlArrayBuffer, buffers.vertices.handle)
        glBindBuffer(GlArrayBuffer, buffers.properties.handle)

        glBindBuffer(GlElementArrayBuffer, buffers.indices.handle)

# shape functions

var sectionsBySides = initTable[int, ShapeSections]()

proc poly*(sides: static[int], color: Vec4, model: Mat4 = mat4()): WrappedShape[Poly] =
    # create sections if they don't already exist
    var sections: ShapeSections
    let firstUsage = not sectionsBySides.contains(sides)

    if firstUsage:
        sections = buffers.newShapeSections(sides)
        sectionsBySides[sides] = sections
    else:
        sections = sectionsBySides[sides]

    # the vertex data is reused for each shape,
    # so we only need to do it once
    if firstUsage:
        var corners: array[sides, Vec2]

        for side in 1 .. sides:
            let angle = (2 * float32(PI)) / sides * float32(side)
            echo "angle: ", angle.toDegrees()

            let x = cos(angle)
            let y = sin(angle)

            let vertex = vec2(x, y)
            let index = side - 1

            corners[index] = vertex
        
        # the center is also the first vertex, so we
        # need to add it as such
        const center = vec2()
        discard sections.vertices.add(center)

        # and now we add the corners
        discard sections.vertices.add(corners)
        echo "adding corners!" & " size: " & $sizeof(corners)
        echo corners

    let poly = Poly(color: color, model: model)
    result.shape = poly
    echo "adding poly!" & " size: " & $sizeof(poly)
    echo poly
    result.offset = sections.properties.add(poly)

    # and now for the indices
    const center = 0'u32
    var triangles: array[sides, array[3, uint32]]

    for side in 1'u32 .. uint32(sides):
        let nextSide = (side mod sides) + 1

        let triangle = [center, side, nextSide]
        let index = int(side) - 1

        triangles[index] = triangle

    echo "adding triangle indices!" & " size: " & $sizeof(triangles)
    echo triangles
    discard sections.indices.add(triangles)

    sections.count += 1

proc drawPolygons*() =
    glUseProgram(program.handle)
    glBindVertexArray(configuration)

    for sections in sectionsBySides.values:
        echo fmt"drawing: (GlTriangles, 3 * {sections.sides}, GlUnsignedInt, {sections.indices.offset}, {sections.count})"
        # huge problem with this implementation: you can't specify offsets for the vertex & property buffers, thus making this system impossible
        glDrawElementsInstanced(GlTriangles, 3'i32 * sections.sides, GlUnsignedInt, cast[pointer](uint32(sections.indices.offset)), sections.count)