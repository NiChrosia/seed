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
    ## pitch and yaw should be in radians

    let
        x = cos(pitch) * cos(yaw)
        y = sin(yaw)
        z = sin(pitch) * cos(yaw)

    return vec3(x, y, z)
