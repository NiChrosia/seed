## A module providing buffers, sections, and construction procs
## to easily allow creation of colored polygons.

import sections, attributes, vmath, shady, windy, opengl
import ../src/seed/video/backends/gl
import ../src/seed/video/[cameras]
import std/[times]

proc processVertex(
    gl_Position: var Vec4, vColor: var Vec4, 
    pos: Vec2, color: Vec4, layer: float, transform: Mat4,
    view: Uniform[Mat4], project: Uniform[Mat4]
) =
    gl_Position = project * view * transform * vec4(pos.x, pos.y, layer, 1f)
    vColor = color

proc processFragment(FragColor: var Vec4, vColor: Vec4) =
    FragColor = vColor

let window = newWindow("Test", ivec2(800, 600), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

var
    vertexShader = newShader(GlVertexShader, toGLSL(processVertex))
    fragmentShader = newShader(GlFragmentShader, toGLSL(processFragment))

    program = newProgram()

program.shaders = (vertexShader, fragmentShader)
program.link()

var configuration: uint32
glGenVertexArrays(1, addr configuration)

var vertices = newBuffer(GlDynamicDraw)
var properties = newBuffer(GlDynamicDraw)
var elements = newBuffer(GlDynamicDraw)

var triVertices = vertices.newSection()
var triProperties = properties.newSection()
var triElements = elements.newSection()

type
    TriVertex = object
        pos: Vector[2, float32]

    TriangleRepr = object
        color: Vector[4, float32]
        layer: float32
        transform: SquareMatrix[4, float32]

    Triangle = object
        color: Vec4
        layer: float32
        transform: Mat4

type
    WrappedShape*[S] = object
        shape*: S
        offset*: int32

proc triangle(transform: Mat4, color: Vec4, layer: float32): WrappedShape[Triangle] =
    once:
        let vertices: array[3, Vector[2, float32]] = [
            [-1f, -1f],
            [1f, -1f],
            [0f, 1f]
        ]

        discard triVertices.add(vertices)
    
    block:
        let triangle = Triangle(color: color, layer: layer, transform: transform)
        let offset = triProperties.add(triangle)

        result = WrappedShape[Triangle](shape: triangle, offset: offset)

    block:
        let indices: array[3, uint32] = [0'u32, 1, 2]
        discard triElements.add(indices)

discard triangle(mat4(), vec4(1f, 0f, 1f, 1f), 0f)

glBindVertexArray(configuration)

glBindBuffer(GlArrayBuffer, vertices.handle)
declareAttributes(program.handle, TriVertex)

glBindBuffer(GlArrayBuffer, properties.handle)
declareAttributes(program.handle, TriangleRepr, true)

glBindBuffer(GlElementArrayBuffer, elements.handle)

var
    movement = newMovement3D(0.5f, wasdSpaceShift)
    rotation = newMouseRotation(1f)

    camera = newCamera3D(vec3(0f, 0f, 15f), movement, vec3(0f, 0f, -1f), vec3(0f, 1f, 0f), rotation)

var
    view = program.newUniform[:Mat4]("view", updateMatrix)
    project = program.newUniform[:Mat4]("project", updateMatrix)

with(program, false):
    view.update(mat4())
    project.update(perspective(45f, window.size.x / window.size.y, 0.1f, 10000f))

var triangleCount = 1'i32

window.onResize = proc() =
    glViewport(0, 0, window.size.x, window.size.y)

proc handleInput() =
    camera.move(window.buttonDown)

proc handleMousePress() =
    if window.buttonDown[MouseLeft]:
        let matrix = block:
            let translation = translate(camera.position)
            let offset = translate(camera.front * 50f)

            let angle = arctan2(
                -camera.front.z,
                -camera.front.x
            ) + 90f

            let rotation = rotateY(angle)

            offset * translation * rotation

        let color = block:
            let time = epochTime()

            let red = sin(time)
            let green = sin(time + 1f)
            let blue = sin(time + 2f)

            vec4(red, green, blue, 1f)

        discard triangle(matrix, color, 0f)
        inc triangleCount

window.onMouseMove = proc() =
    camera.rotate(window.mousePos)

proc renderFrame() =
    glClearColor(0.2f, 0.3f, 0.3f, 1f)
    glClear(GL_COLOR_BUFFER_BIT)

    glUseProgram(program.handle)
    glBindVertexArray(configuration)

    view.update(camera.matrix)

    glDrawElementsInstanced(GL_TRIANGLES, 3, GL_UNSIGNED_INT, nil, triangleCount)

while not window.closeRequested:
    handleInput()
    renderFrame()
    handleMousePress()

    window.swapBuffers()
    pollEvents()