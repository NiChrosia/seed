import ../src/seed/windowing, ../src/seed/gl/poly
import vmath, times

#[

a few things need to be addressed before this
can be considered good enough, which are the following:

- the high-level code is directly interacting with
  opengl, via poly.minimumProgram(), which is
  somewhat awkward, and should be replaced with
  a cleaner solution

- the current window layer serves little purpose
  other than syntax sugar, so should either
  provide fairly significant benefit, or be removed.

]#

let window = newWindow("Triangle!", 600, 600, (3, 3))

let program = poly.minimumProgram()
poly.init(program)

window.onFrame = proc() =
    clear(0f, 0f, 0f, 1f)

    proc t(shift: float = 0f, max: float32 = 1f, scale: float = 1f): float32 =
        let now = epochTime()
        let scaled = now * scale
        let shifted = scaled + shift

        return shifted mod max

    poly(3, vec4(t(), t(shift = 0.3f, scale = 1.5f), t(shift = 0.6f), 1f), rotate(t(max = TAU), vec3(0f, 0f, 1f)))

    poly.draw()
    poly.clear()

while not window.closeRequested:
    window.swapBuffers()
    pollEvents()
