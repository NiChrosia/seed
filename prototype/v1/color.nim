import poly/color
import ../src/seed/video/backends/gl, ../src/seed/video/cameras

import vmath, windy, chroma
import opengl

import std/[times]

let window = newWindow("Test", ivec2(800, 600), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

var
    movement = newMovement3D(0.125f, wasdSpaceShift)
    rotation = newMouseRotation(1f)

    camera = newCamera3D(vec3(0f, 0f, 15f), movement, vec3(0f, 0f, -1f), vec3(0f, 1f, 0f), rotation)

initializeColorPolygons()

with(color.program, false):
    color.view.update(mat4())
    color.project.update(perspective(45f, window.size.x / window.size.y, 0.1f, 10000f))

discard colorPoly(4, vec4(vec3(1f), 1f))

window.onResize = proc() =
    glViewport(0, 0, window.size.x, window.size.y)

proc handleInput() =
    camera.move(window.buttonDown)

proc handleMousePress() =
    if window.buttonDown[MouseLeft]:
        let theColor = block:
            let color = hsv(float32(sin(epochTime()) * 60f + 240f), 100f, 100f)
            let rgb = color.asRgb()

            proc normalize(value: uint8): float32 =
                let asFloat = float32(value)
                return asFloat / 255f

            let red = normalize(rgb.r)
            let green = normalize(rgb.g)
            let blue = normalize(rgb.b)

            vec4(red, green, blue, 1f)

        let matrix = block:
            let translation = translate(camera.position)
            let offset = translate(camera.front * 50f)

            let rotTime = float32(epochTime() mod 6f) * 60f
            let altTime = float32(sin(epochTime()))
            let rotation = rotateZ(rotTime.toRadians() * altTime)

            offset * translation * rotation

        discard colorPoly(6, theColor, matrix)

window.onMouseMove = proc() =
    camera.rotate(window.mousePos)

proc renderFrame() =
    glClearColor(0.2f, 0.3f, 0.3f, 1f)
    glClear(GL_COLOR_BUFFER_BIT)

    glUseProgram(color.program.handle)
    color.view.update(camera.matrix())

    drawColorPolygons()

while not window.closeRequested:
    handleInput()
    renderFrame()
    handleMousePress()

    window.swapBuffers()
    pollEvents()