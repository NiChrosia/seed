import ../src/seed/windowing, ../src/seed/gl/poly
import vmath

let window = newWindow("Triangle!", 600, 600, (3, 3))

let program = poly.minimumProgram()
poly.init(program)

poly(3, vec4(1f, 1f, 1f, 1f))

window.onFrame = proc() =
    clear(0f, 0f, 0f, 1f)

    poly.draw()

while not window.closeRequested:
    window.swapBuffers()
    pollEvents()