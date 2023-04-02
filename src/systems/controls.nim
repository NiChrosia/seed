import tables
import ../api/rendering/[cameras], ./state
import staticglfw, vmath

{.push cdecl.}
proc onKey(window: Window, key, scancode, action, mods: cint) =
    if action == PRESS:
        keysDown[key] = true
    elif action == RELEASE:
        keysDown[key] = false

proc onMouse(window: Window, x, y: cdouble) =
    proc asVec(x, y: cdouble): Vec2 {.inline.} =
        return vec2(float32(x), float32(y))

    var initialPos {.global.} = vec2(0f, 0f)
    var isFirst {.global.} = false

    if not isFirst:
        initialPos = asVec(x, y)
        isFirst = true

    mousePos = asVec(x, y) - initialPos
{.pop.}

proc update*() =
    proc `[]`(keys: Table[int, bool], key: int, default: bool): bool {.inline.} =
        return keys.getOrDefault(key, default)

    if keysDown[KEY_W, false]:
        camera.position += camera.front * 0.1f
    if keysDown[KEY_S, false]:
        camera.position -= camera.front * 0.1f
    if keysDown[KEY_D, false]:
        camera.position += cross(camera.front, camera.top) * 0.1f
    if keysDown[KEY_A, false]:
        camera.position -= cross(camera.front, camera.top) * 0.1f
    if keysDown[KEY_SPACE, false]:
        camera.position += camera.top * 0.1f
    if keysDown[KEY_LEFT_SHIFT, false]:
        camera.position -= camera.top * 0.1f

    let
        realX = mousePos.x
        realY = -mousePos.y

    camera.front = calculateFront(pitch = realX.toRadians, yaw = clamp(realY, -89f, 89f).toRadians)

proc setCallbacks*() =
    discard window.setKeyCallback(onKey)
    discard window.setCursorPosCallback(onMouse)
