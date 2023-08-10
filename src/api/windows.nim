import staticglfw as glfw, opengl, vmath
import std/[tables]

type
    CursorState* = enum
        csNormal, csHidden, csDisabled

    TrackingWindow* = ref object
        window*: Window
        size*: IVec2

        keysDown*: Table[int, bool]

        onKey*: proc(key, scancode, action, mods: cint)
        onMouseMove*: proc()
        onClick*: proc(button, action, mods: cint)

# lifetime
proc init*(
    _: typedesc[TrackingWindow],
    title: string,
    size: IVec2,
    version: tuple[major, minor: int, core: bool]
): TrackingWindow =
    # - glfw window
    windowHint(VERSION_MAJOR, cint(version.major))
    windowHint(VERSION_MINOR, cint(version.minor))
    windowHint(OPENGL_CORE_PROFILE, cint(version.core))

    let window = createWindow(size.x, size.y, "Gamma", nil, nil)

    window.makeContextCurrent()
    loadExtensions()

    # - twindow object
    result = new(TrackingWindow)
    result.window = window
    result.size = size
    
    # - callbacks
    # cursed, but it works
    var copy {.global.} = result

    proc onResize(window: Window, width: cint, height: cint) {.cdecl.} =
        glViewport(0, 0, GLint(width), GLint(height))
        copy.size = ivec2(int32(width), int32(height))

    proc onKey(window: Window, key, scancode, action, mods: cint) {.cdecl.} =
        block updateKeys:
            if action == PRESS:
                copy.keysDown[key] = true
            elif action == RELEASE:
                copy.keysDown[key] = false

        if copy.onKey != nil:
            copy.onKey(key, scancode, action, mods)

    proc onMouse(window: Window, x, y: cdouble) {.cdecl.} =
        if copy.onMouseMove != nil:
            copy.onMouseMove()
    
    proc onClick(window: Window, button, action, mods: cint) {.cdecl.} =
        if copy.onClick != nil:
            copy.onClick(button, action, mods)

    discard window.setFramebufferSizeCallback(onResize)
    discard window.setKeyCallback(onKey)
    discard window.setCursorPosCallback(onMouse)
    discard window.setMouseButtonCallback(onClick)
    
    # - setting default key values
    for i in KEY_UNKNOWN .. KEY_LAST:
        result.keysDown[i] = false

proc terminate*(twindow: var TrackingWindow) =
    destroyWindow(twindow.window)

# passthrough
proc shouldClose*(twindow: TrackingWindow): bool =
    return windowShouldClose(twindow.window) != 0

proc mousePos*(twindow: TrackingWindow): Vec2 =
    var x, y: cdouble
    getCursorPos(twindow.window, addr x, addr y)

    return vec2(x, y)

proc relativeMousePos*(twindow: TrackingWindow): Vec2 =
    let current = twindow.mousePos
    var initial {.global.}: Vec2
    
    once:
        initial = current
    
    return current - initial

proc `mousePos=`*(twindow: var TrackingWindow, pos: Vec2) =
    setCursorPos(twindow.window, cdouble(pos.x), cdouble(pos.y))

proc `cursorState=`*(twindow: var TrackingWindow, state: CursorState) =
    let mode = case state
    of csNormal: CURSOR_NORMAL
    of csHidden: CURSOR_HIDDEN
    of csDisabled: CURSOR_DISABLED
    
    setInputMode(twindow.window, CURSOR, cint(mode))