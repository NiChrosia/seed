import vmath

type
    Camera3* = object
        position*, top*, front*: Vec3

proc init*(_: typedesc[Camera3], position: Vec3 = vec3(), front: Vec3 = vec3(0f, 0f, -1f)): Camera3 =
    result.position = position
    result.top      = vec3(0f, 1f, 0f)
    result.front    = front

proc matrix*(camera: Camera3): Mat4 =
    return lookAt(camera.position, camera.position + camera.front, camera.top)

proc calculateFront*(pitch, yaw: float32): Vec3 =
    let
        x = cos(yaw) * cos(pitch)
        y = sin(pitch)
        z = sin(yaw) * cos(pitch)

    return normalize(vec3(x, y, z))
