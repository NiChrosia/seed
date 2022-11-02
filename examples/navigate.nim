import ../src/seed/gl/poly
import ../src/seed/gl/shaders/[types, shaders, programs, uniforms], ../src/seed/gl/cameras

import vmath, windy, shady
import opengl

import std/random

randomize()

when defined(windows):
  let window = newWindow("Test", ivec2(800, 600), openglVersion = Opengl3Dot3)
else:
  let window = newWindow("Test", ivec2(800, 600), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

var
    movement = newMovement3D(0.125f, wasdSpaceShift)
    rotation = newMouseRotation(1f)

    camera = newCamera3D(
        movement, rotation,
        initialPosition = vec3(0f, 0f, 15f), 
        initialFront = vec3(0f, 0f, -1f),
        initialTop = vec3(0f, 1f, 0f)
    )

proc processVertex(
    gl_Position: var Vec4, vColor: var Vec4, 
    pos: Vec2, color: Vec4, model: Mat4,
    view: Uniform[Mat4], project: Uniform[Mat4]
) =
    gl_Position = project * view * model * vec4(vec3(pos, 0f), 1f)
    vColor = color

proc processFragment(FragColor: var Vec4, vColor: Vec4) =
    FragColor = vColor

var vertexShader = initShader(sVertex, toGLSL(processVertex), true)
var fragmentShader = initShader(sFragment, toGLSL(processFragment), true)

var program = initProgram([vertexShader, fragmentShader], true)

poly.init(program)

program.use()

var view = program.locate("view")
var project = program.locate("project")

view.set(cast[array[16, float32]](mat4()), false)
project.set(cast[array[16, float32]](perspective(45f, window.size.x / window.size.y, 0.1f, 10000f)), false)

poly(4, vec4(vec3(1f), 1f))

window.onResize = proc() =
    glViewport(0, 0, window.size.x, window.size.y)

# A, T, C, G
const bases = [
    vec3(1f, 0f, 0f),
    vec3(1f, 0f, 1f),
    vec3(0f, 1f, 0f),
    vec3(0f, 0.5f, 1f),
]

proc onClick() =
    block:
        let matrix = translate(camera.position)
            .`*` translate(camera.front * 50f)
            .`*` rotate(-arctan2(camera.front.x, camera.front.z), vec3(0f, 1f, 0f))
            .`*` rotate(TAU.float32 / 8f, vec3(0f, 0f, 1f))
            .`*` scale(vec3(2f, 2f, 1f))

        poly(4, vec4(0f, 0.5f, 1f, 1f), matrix)

    block:
        let matrix = translate(camera.position)
            .`*` translate(camera.front * 50f)
            .`*` translate(camera.top * 2f)
            .`*` rotate(-arctan2(camera.front.x, camera.front.z), vec3(0f, 1f, 0f))
            .`*` rotate(TAU.float32 / 8f, vec3(0f, 0f, 1f))

        poly(4, vec4(1f, 0f, 1f, 1f), matrix)

    block:
        let matrix = translate(camera.position)
            .`*` translate(camera.front * 50f)
            .`*` translate(camera.right * 2f)
            .`*` rotate(-arctan2(camera.front.x, camera.front.z), vec3(0f, 1f, 0f))
            .`*` scale(vec3(2f, 1f, 1f))
            .`*` rotate(TAU.float32 / 8f, vec3(0f, 0f, 1f))

        poly(4, vec4(bases[rand(0..3)], 1f), matrix)

proc handleInput() =
    camera.move(window.buttonDown)

    if window.buttonDown[MouseLeft]:
        onClick()

window.onMouseMove = proc() =
    camera.rotate(window.mousePos)

window.onFrame = proc() =
    glClearColor(0.2f, 0.3f, 0.3f, 1f)
    glClear(GL_COLOR_BUFFER_BIT)

    program.use()
    view.set(cast[array[16, float32]](camera.matrix()), false)

    poly.draw()

while not window.closeRequested:
    handleInput()

    window.swapBuffers()
    pollEvents()
