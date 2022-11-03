import ../src/seed/windowing, ../src/seed/gl/poly
import vmath

#[

a few things need to be addressed before this
can be considered good enough, which are the following:

- polygons stay on the screen; this can either be
  fixed by making objects deleted after one frame,
  or allowing manipulation of existing objects

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

poly(3, vec4(1f, 1f, 1f, 1f))

window.onFrame = proc() =
    clear(0f, 0f, 0f, 1f)

    poly.draw()

while not window.closeRequested:
    window.swapBuffers()
    pollEvents()