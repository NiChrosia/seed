import ./state
import staticglfw as glfw, opengl, vmath

proc onResize(window: Window, width: cint, height: cint) {.cdecl.} =
    glViewport(0, 0, GLint(width), GLint(height))
    WINDOW_SIZE = ivec2(int32(width), int32(height))

proc initialize*(title: string, size: IVec2, version: tuple[major, minor: int, core: bool]) =
    if glfw.init() == 0:
        raise Exception.newException("Failed to initalize GLFW!")

    window = block:
        windowHint(VERSION_MAJOR, cint(version.major))
        windowHint(VERSION_MINOR, cint(version.minor))
        windowHint(OPENGL_CORE_PROFILE, cint(version.core))

        createWindow(size.x, size.y, "Gamma", nil, nil)

    window.makeContextCurrent()
    loadExtensions()

    WINDOW_SIZE = size

    # callbacks
    discard window.setFramebufferSizeCallback(onResize)

proc terminate*() =
    destroyWindow(window)
    glfw.terminate()
