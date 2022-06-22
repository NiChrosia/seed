import vmath, windy, std/[tables, sugar, with]

export vmath, windy, tables, sugar

type
    # movement

    Movement*[C, V] = object of RootObj
        buttons: seq[Button]
        effectOf: (C, Button) -> V

    # rotation

    Rotation*[I, R] = object of RootObj
        process: (I) -> R

    # camera

    MovableCamera*[S, V] = object of RootObj
        position*: V
        movement: Movement[S, V]

    RotatableCamera*[S, V, I, R] = object of MovableCamera[S, V]
        front*, top*: R
        rotation: Rotation[I, R]

    Camera2D* = object of MovableCamera[Camera2D, Vec2]
    CameraFlat3D* = object of MovableCamera[CameraFlat3D, Vec3]

    Camera3D* = object of RotatableCamera[Camera3D, Vec3, IVec2, Vec3]

    # concepts

# proc-based properties

proc right*[S](camera: S): auto =
    result = cross(camera.front, camera.top)

proc matrix*(camera: Camera2D): Mat3 =
    result = translate(-camera.position)

proc matrix*(camera: CameraFlat3D): Mat4 =
    result = translate(vec3(-camera.position.xy, 0f))

proc matrix*(camera: Camera3D): Mat4 =
    result = lookAt(camera.position, camera.position + camera.front, camera.top)

# direct effects

proc move*[S](camera: var S, active: ButtonView) =
    for button in camera.movement.buttons:
        if active[button]:
            let effect = camera.movement.effectOf(camera, button)
            
            camera.position += effect

proc rotate*[S, I](camera: var S, input: I) =
    camera.front = camera.rotation.process(input)

# initialization

## movement

### presets

let
    wasd* = {
        KeyW: vec2(0f, 1f),
        KeyS: vec2(0f, -1f),
        KeyD: vec2(1f, 0f),
        KeyA: vec2(-1f, 0f)
    }.toTable

    wasdSpaceShiftFlat* = {
        KeyS: vec3(0f, 0f, 1f),
        KeyW: vec3(0f, 0f, -1f),
        KeyD: vec3(1f, 0f, 0f),
        KeyA: vec3(-1f, 0f, 0f),
        KeySpace: vec3(0f, 1f, 0f),
        KeyLeftShift: vec3(0f, -1f, 0f)
    }.toTable

    # for whatever reason, tables require procs marked with {.closure.}
    wasdSpaceShift* = {
        KeyW: (front: Vec3, top: Vec3, right: Vec3) {.closure.} => front,
        KeyS: (front: Vec3, top: Vec3, right: Vec3) {.closure.} => -front,
        KeyD: (front: Vec3, top: Vec3, right: Vec3) {.closure.} => right,
        KeyA: (front: Vec3, top: Vec3, right: Vec3) {.closure.} => -right,
        KeySpace: (front: Vec3, top: Vec3, right: Vec3) {.closure.} => top,
        KeyLeftShift: (front: Vec3, top: Vec3, right: Vec3) {.closure.} => -top
    }.toTable

### flat movement

proc newMovement2D*[C](modifier: float32, effects: Table[Button, Vec2]): Movement[C, Vec2] =
    var buttons = newSeq[Button]()

    for button in effects.keys:
        buttons.add(button)

    proc effectOf(camera: C, button: Button): Vec2 =
        result = effects[button] * modifier

    with(result):
        buttons = buttons
        effectOf = effectOf

proc newMovementFlat3D*[C](modifier: float32, effects: Table[Button, Vec3]): Movement[C, Vec3] =
    var buttons = newSeq[Button]()

    for button in effects.keys:
        buttons.add(button)

    proc effectOf(camera: C, button: Button): Vec3 =
        result = effects[button] * modifier

    with(result):
        buttons = buttons
        effectOf = effectOf

### flat movement

proc newMovement3D*(modifier: float32, effects: Table[Button, (front: Vec3, top: Vec3, right: Vec3) -> Vec3]): Movement[Camera3D, Vec3] =
    var buttons = newSeq[Button]()

    for button in effects.keys:
        buttons.add(button)

    proc effectOf(camera: Camera3D, button: Button): Vec3 =
        let function = effects[button]
        result = function(camera.front, camera.top, camera.right)

    with(result):
        buttons = buttons
        effectOf = effectOf

## rotation

proc newMouseRotation*(modifier: float32, shiftToZ, invertYaw, clampYaw: bool = true): Rotation[IVec2, Vec3] =
    # individual steps

    proc convert(coordinates: IVec2): Vec2 =
        result = vec2(coordinates)

    proc ready(vector: Vec2): Vec2 =
        result = vector

        if shiftToZ:
            result.x -= 90

        if invertYaw:
            result.y = 360 - result.y

        if clampYaw:
            result.y = clamp(result.y, -89, 89)

    proc finalize(vector: Vec2): Vec3 =
        let
            x = cos(vector.x.toRadians) * cos(vector.y.toRadians)
            y = sin(vector.y.toRadians)
            z = sin(vector.x.toRadians) * cos(vector.y.toRadians)

        vec3(x, y, z)

    # entire operation

    proc process(input: IVec2): Vec3 =
        let converted = convert(input)
        let readied = ready(converted)
        let finalized = finalize(readied)

        result = finalized

    # assignment

    result.process = process

## cameras

proc newCamera2D*(initialPosition: Vec2, movement: Movement[Camera2D, Vec2]): Camera2D =
    with(result):
        position = initialPosition
        movement = movement

proc newCameraFlat3D*(initialPosition: Vec3, movement: Movement[CameraFlat3D, Vec3]): CameraFlat3D =
    with(result):
        position = initialPosition
        movement = movement

proc newCamera3D*(
    initialPosition: Vec3,
    movement: Movement[Camera3D, Vec3],

    initialFront, initialTop: Vec3,
    rotation: Rotation[IVec2, Vec3]
): Camera3D =
    with(result):
        position = initialPosition
        movement = movement

        front = initialFront
        top = initialTop
        rotation = rotation

## cameras

# initialization