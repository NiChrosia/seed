import windy
import opengl

export windy

proc newWindow*(title: string, w, h: int32, opengl: tuple[major, minor: int]): Window =
    result = newWindow(title, ivec2(w, h), openglMajorVersion = opengl.major, openglMinorVersion = opengl.minor)

    result.makeContextCurrent()
    loadExtensions()

# drawing
proc clear*(r, g, b, a: float32) =
    glClearColor(r, g, b, a)
    glClear(GL_COLOR_BUFFER_BIT)
