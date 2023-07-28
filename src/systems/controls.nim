import tables
import ../api/rendering/[cameras], "."/[state, windows]
import staticglfw, vmath

type
    Control* = ref object
        cameraSpeed*: float

        cameraFrozen*: bool
        frozenMousePos*: Vec2

proc init*(_: typedesc[Control], cameraSpeed: float): Control =
    result = new(Control)
    result.cameraSpeed = cameraSpeed
    
    var copy = result

    proc onClick(button, action, mods: cint) =
        if button == MOUSE_BUTTON_LEFT and action == PRESS and copy.cameraFrozen:
            twindow.cursorState = csDisabled
            twindow.mousePos = copy.frozenMousePos
            copy.cameraFrozen = false
    
    twindow.onClick = onClick
    twindow.cursorState = csDisabled

proc updatePosition*(control: Control) =
    template down(key: cint): bool =
        twindow.keysDown[key]

    if down KEY_W:
        camera.position += camera.front * control.cameraSpeed
    if down KEY_S:
        camera.position -= camera.front * control.cameraSpeed
    if down KEY_D:
        camera.position += cross(camera.front, camera.top) * control.cameraSpeed
    if down KEY_A:
        camera.position -= cross(camera.front, camera.top) * control.cameraSpeed
    if down KEY_SPACE:
        camera.position += camera.top * control.cameraSpeed
    if down KEY_CAPS_LOCK:
        camera.position -= camera.top * control.cameraSpeed

proc updateRotation*(control: Control) =
    let
        mousePos = twindow.relativeMousePos

        increasingY = -mousePos.y
        increasingX = mousePos.x
        
        pitchDegrees = clamp(increasingY, -89.99f, 89.99f)
        
        pitch = pitchDegrees.toRadians
        yaw = increasingX.toRadians

    camera.front = calculateFront(pitch, yaw)

proc update*(control: var Control) =
    if twindow.keysDown[KEY_ESCAPE] and not control.cameraFrozen:
        control.frozenMousePos = twindow.mousePos
        # the change in state *must* be after setting the frozen position, because 
        # otherwise, mousePos returns the center of the window
        twindow.cursorState = csNormal
        control.cameraFrozen = true
    
    if not control.cameraFrozen:
        updatePosition(control)
        updateRotation(control)