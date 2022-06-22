import windy, std/[tables, with]

type
    CameraInput*[S] = object of RootObj
        sensitivity*: S

    SpatialInput*[V] = object of CameraInput[float32]
        ## the effects for this input, such as W for forward
        ## a set of the buttons for iteration can be obtained by
        ## effects.keys
        effects*: Table[Button, proc(front: V, top: V): V {.noSideEffect, gcsafe, locks: 0.}]

    AngleInput*[V] = object of CameraInput[float32]
        ## rotation values like yaw, pitch, and roll, inside a vector
        rotation*: V

        ## the ratio of 360 to the screen dimensions, used to
        ## coerce screen coordinates into the range of degrees
        degreeRatio: V

        ## any additional transformations, most notably
        ## adding -90 to yaw to make it face -Z, inverting
        ## pitch as y goes from top-to-bottom on the screen,
        ## and clamping pitch to avoid unintentional input flipping
        transform: proc(vector: V): V

        ## converts all the rotations to a usable vector facing
        ## from the front of the camera
        toDirection: proc(rotation: V): V

    Camera*[V] = object of RootObj
        pos*: V
        front*, top*: V

        spatialInput*: SpatialInput[V]
        angleInput*: AngleInput[V]

# properties

proc matrix*[V](camera: Camera[V]): Mat4 =
    result = lookAt(camera.pos, camera.pos + camera.front, camera.top)

proc right*[V](camera: Camera[V]): V =
    result = cross(camera.front, camera.top)

# updates

proc update*[V](input: SpatialInput[V], view: ButtonView, front, top: V): V =
    for button in input.effects.keys:
        if view[button]:
            let function = input.effects[button]
            let vector = function(front, top) * input.sensitivity

            result += vector

proc update*[V](input: var AngleInput[V], previousMouse, currentMouse: V): V =
    let difference = (currentMouse - previousMouse) * input.degreeRatio * input.sensitivity
    input.rotation += difference
    let transformed = input.transform(input.rotation)

    let direction = input.toDirection(transformed)
    result = normalize(direction)

# initialization

proc newCamera*[V](pos, front, top: V, spatialInput: SpatialInput[V], angleInput: AngleInput[V]): Camera[V] =
    with(result):
        pos = pos
        front = front
        top = top

        spatialInput = spatialInput
        angleInput = angleInput

proc newSpatialInput2D*(
    sensitivity: float32,
    up: Button = KeyW, 
    down: Button = KeyS, 
    left: Button = KeyA, 
    right: Button = KeyD
): SpatialInput[Vec2] =
    with(result):
        sensitivity = sensitivity

        # why does Nim require {.closure.}
        effects = {
            up: proc(front, top: Vec2): Vec2 {.closure.} = top,
            down: proc(front, top: Vec2): Vec2 {.closure.} = -top,
            left: proc(front, top: Vec2): Vec2 {.closure.} = -front,
            right: proc(front, top: Vec2): Vec2 {.closure.} = front
        }.toTable

proc newSpatialInput3D*(
    sensitivity: float32,
    front: Button = KeyW, 
    back: Button = KeyS, 
    left: Button = KeyA, 
    right: Button = KeyD,
    up: Button = KeySpace,
    down: Button = KeyLeftShift
): SpatialInput[Vec3] =
    with(result):
        sensitivity = sensitivity

        effects = {
            front: proc(front, top: Vec3): Vec3 {.closure.} = front,
            back: proc(front, top: Vec3): Vec3 {.closure.} = -front,
            left: proc(front, top: Vec3): Vec3 {.closure.} = -cross(front, top),
            right: proc(front, top: Vec3): Vec3 {.closure.} = cross(front, top),
            up: proc(front, top: Vec3): Vec3 {.closure.} = top,
            down: proc(front, top: Vec3): Vec3 {.closure.} = -top,
        }.toTable

proc newAngleInput*(sensitivity: float32, windowSize: IVec2): AngleInput[Vec3] =
    proc transform(vector: Vec3): Vec3 =
        result = vector

        result.x -= 90

        result.y = 360f - result.y
        result.y = clamp(result.y, -89f, 89f)

    proc toDirection(rotation: Vec3): Vec3 =
        let
            x = cos(rotation.x.toRadians) * cos(rotation.y.toRadians)
            y = sin(rotation.y.toRadians)
            z = sin(rotation.x.toRadians) * cos(rotation.y.toRadians)

        vec3(x, y, z)

    with(result):
        sensitivity = sensitivity

        rotation = vec3(0f, 0f, 0f)
        degreeRatio = vec3(360 / windowSize.x, 360 / windowSize.y, 0f)
        
        transform = transform
        toDirection = toDirection