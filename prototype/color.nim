## A module providing buffers, sections, and construction procs
## to easily allow creation of colored polygons.

import sections, vmath, windy, opengl
import ../src/seed/video/backends/gl
import ../src/seed/video/[cameras]
import std/[times]

from polycolor import poly

let window = newWindow("Test", ivec2(800, 600), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

polycolor.initialize()
polycolor.configure()

var
    movement = newMovement3D(0.5f, wasdSpaceShift)
    rotation = newMouseRotation(1f)

    camera = newCamera3D(vec3(0f, 0f, 15f), movement, vec3(0f, 0f, -1f), vec3(0f, 1f, 0f), rotation)

with(polycolor.program, false):
    polycolor.view.update(mat4())
    polycolor.project.update(perspective(45f, window.size.x / window.size.y, 0.1f, 10000f))

polycolor.configure()

discard poly(4, vec4(vec3(1f), 1f))

window.onResize = proc() =
    glViewport(0, 0, window.size.x, window.size.y)

proc handleInput() =
    camera.move(window.buttonDown)

proc handleMousePress() =
    if window.buttonDown[MouseLeft]:
        let matrix = block:
            #let translation = translate(camera.position)
            #let offset = translate(camera.front * 50f)

            # let angle = arctan2(
            #     -camera.front.z,
            #     -camera.front.x
            # ) + float32(PI) / 2f

            # let rotation = rotateY(angle)

            #offset * translation * rotation
            mat4()

        let color = block:
            let time = epochTime()

            let red = sin(time)
            let green = sin(time + 1f)
            let blue = sin(time + 2f)

            vec4(red, green, blue, 1f)

        discard poly(6, color, matrix)

window.onMouseMove = proc() =
    camera.rotate(window.mousePos)

proc renderFrame() =
    glClearColor(0.2f, 0.3f, 0.3f, 1f)
    glClear(GL_COLOR_BUFFER_BIT)

    glUseProgram(polycolor.program.handle)
    polycolor.view.update(camera.matrix)

    polycolor.drawPolygons()

while not window.closeRequested:
    handleInput()
    renderFrame()
    handleMousePress()

    window.swapBuffers()
    pollEvents()