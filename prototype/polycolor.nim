import buffers, attributes
import ../src/seed/video/backends/gl

import opengl
import vmath, shady

import std/[tables, strformat]

# utility
type
    ShapeBuffers = ref object
        sides, count: int32

        vertices, properties, indices: buffers.Buffer

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

proc newShapeBuffers(usage: GlEnum, sides: int32): ShapeBuffers =
    result = new(ShapeBuffers)

    result.sides = sides

    result.vertices = newBuffer(usage)
    result.properties = newBuffer(usage)
    result.indices = newBuffer(usage)

# end utility

var
    vertexShader, fragmentShader: Shader
    program*: ShaderProgram

    view*, project*: ShaderUniform[Mat4]

proc initialize*() =
    # shaders
    vertexShader = newShader(GlVertexShader, toGLSL(processVertex))
    fragmentShader = newShader(GlFragmentShader, toGLSL(processFragment))

    program = newProgram()

    program.shaders = (vertexShader, fragmentShader)
    program.link()

    view = program.newUniform[:Mat4]("view", updateMatrix)
    project = program.newUniform[:Mat4]("project", updateMatrix)

# shape functions

var configurationBySides = initTable[int, uint32]()
var buffersBySides = initTable[int, ShapeBuffers]()

proc poly*(sides: static[int], color: Vec4, model: Mat4 = mat4()): WrappedShape[Poly] =
    # create sections if they don't already exist
    var buffers: ShapeBuffers
    let firstUsage = not buffersBySides.contains(sides)

    if firstUsage:
        # initialization
        var configuration: uint32
        glGenVertexArrays(1, addr configuration)
        configurationBySides[sides] = configuration

        buffers = newShapeBuffers(GlDynamicDraw, sides)
        buffersBySides[sides] = buffers

        # state configuration
        glBindVertexArray(configuration)

        buffers.vertices.bindTo(GlArrayBuffer)
        declareAttributes(program.handle, PolyVertex)

        buffers.properties.bindTo(GlArrayBuffer)
        declareAttributes(program.handle, PolyRepr, true)

        buffers.indices.bindTo(GlElementArrayBuffer)
    else:
        buffers = buffersBySides[sides]

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
        discard buffers.vertices.add(center)

        # and now we add the corners
        discard buffers.vertices.add(corners)
        echo "adding corners!" & " size: " & $sizeof(corners)
        echo corners

    let poly = Poly(color: color, model: model)
    result.shape = poly
    echo "adding poly!" & " size: " & $sizeof(poly)
    echo poly
    result.offset = buffers.properties.add(poly)

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
    discard buffers.indices.add(triangles)

    buffers.count += 1

proc drawPolygons*() =
    glUseProgram(program.handle)

    for sides in buffersBySides.keys:
        let configuration = configurationBySides[sides]
        let buffers = buffersBySides[sides]

        glBindVertexArray(configuration)

        echo fmt"drawing: (GlTriangles, 3 * {buffers.sides}, GlUnsignedInt, nil, {buffers.count})"
        glDrawElementsInstanced(GlTriangles, 3'i32 * buffers.sides, GlUnsignedInt, nil, buffers.count)