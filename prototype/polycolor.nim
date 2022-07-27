import sections, attributes
import ../src/seed/video/backends/gl

import opengl
import vmath, shady

import std/[tables]

type
    PolyVertex = object
        pos: Vector[2, float32]

    PolyRepr = object
        color: Vector[4, float32]
        model: SquareMatrix[4, float32]

    Poly = object
        color: Vec4
        model: Mat4

    WrappedShape*[S] = object
        shape: S
        offset: int32

proc processVertex(
    gl_Position: var Vec4, vColor: var Vec4, 
    pos: Vec2, color: Vec4, model: Mat4,
    view: Uniform[Mat4], project: Uniform[Mat4]
) =
    gl_Position = project * view * model * vec4(vec3(pos, 0f), 1f)
    vColor = color

proc processFragment(FragColor: var Vec4, vColor: Vec4) =
    FragColor = vColor

var
    vertexShader, fragmentShader: Shader
    program: ShaderProgram

    vertices, properties, indices: sections.Buffer

    configuration: uint32

proc initialize*() =
    # shaders
    vertexShader = newShader(GlVertexShader, toGLSL(processVertex))
    fragmentShader = newShader(GlFragmentShader, toGLSL(processFragment))

    program = newProgram()

    program.shaders = (vertexShader, fragmentShader)
    program.link()

    # buffers
    vertices = newBuffer(GlDynamicDraw)
    properties = newBuffer(GlDynamicDraw)
    indices = newBuffer(GlDynamicDraw)

    # vertex array
    glGenVertexArrays(1, addr configuration)

proc use*() =
    glBindVertexArray(configuration)

    var firstTime {.global.} = true

    if firstTime:
        glBindBuffer(GlArrayBuffer, vertices.handle)
        declareAttributes(program.handle, PolyVertex)

        glBindBuffer(GlArrayBuffer, properties.handle)
        declareAttributes(program.handle, PolyRepr, true)

        firstTime = false
    else:
        glBindBuffer(GlArrayBuffer, vertices.handle)

    glBindBuffer(GlElementArrayBuffer, indices.handle)

# shape functions

proc poly(sides: static[int], radius: float32, color: Vec4, model: Mat4 = mat4()): WrappedShape[Poly] =
    discard

proc drawPolygons() =
    discard