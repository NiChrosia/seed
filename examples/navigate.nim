import ../src/seed/gl/poly/color
import ../src/seed/gl/shaders/[programs, uniforms], ../src/seed/gl/cameras

import vmath, windy, chroma
import opengl

import std/[times]

when defined(windows):
  let window = newWindow("Test", ivec2(800, 600), openglVersion = Opengl3Dot3)
else:
  let window = newWindow("Test", ivec2(800, 600), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

var
    movement = newMovement3D(0.125f, wasdSpaceShift)
    rotation = newMouseRotation(1f)

    camera = newCamera3D(vec3(0f, 0f, 15f), movement, vec3(0f, 0f, -1f), vec3(0f, 1f, 0f), rotation)

initializeColorPolygons()

color.program.use()

color.view.set(cast[array[16, float32]](mat4()), false)
color.project.set(cast[array[16, float32]](perspective(45f, window.size.x / window.size.y, 0.1f, 10000f)), false)

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

    color.program.use()
    color.view.set(cast[array[16, float32]](camera.matrix()), false)

    drawColorPolygons()

while not window.closeRequested:
    handleInput()
    renderFrame()
    handleMousePress()

    window.swapBuffers()
    pollEvents()
