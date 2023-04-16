import ../../src/seed/windowing, ../../src/seed/gl/poly
import vmath, bumpy, terminal

let window = newWindow("Matrix platformer", 600, 600, (3, 3))

let program = poly.minimumProgram()
poly.init(program)

type
    Entity = ref object
        pos*, vel*, size*, forces*: Vec3

proc e*(pos, vel, size: Vec3): Entity =
    result = new Entity

    result.pos = pos
    result.vel = vel
    result.size = size
    result.forces = vec3()

var player = e(vec3(), vec3(), vec3(1f, 1f, 1f))
var scale = 0.1f

var entities: seq[Entity]
entities.add(player)

proc init() =
    entities.add e(vec3(-10f, -10f, 0f), vec3(), vec3(10f, 1f, 1f))
    entities.add e(vec3(-4f, 4f, 0f), vec3(), vec3(1f, 1f, 1f))

proc input() =
    template held(b: Button, code: untyped) =
        if window.buttonDown[b]:
            code

    const movement = 0.5f
    const percentShift = 0.1f

    held KeyW:
        player.vel = mix(player.vel, vec3(0f, movement, 0f), percentShift)
    held KeyA:
        player.vel = mix(player.vel, vec3(-movement, 0f, 0f), percentShift)
    held KeyS:
        player.vel = mix(player.vel, vec3(0f, -movement, 0f), percentShift)
    held KeyD:
        player.vel = mix(player.vel, vec3(movement, 0f, 0f), percentShift)
    held KeySpace:
        player.vel *= 1.1f

proc top(a: Rect): float32 =
    return a.y + a.h

proc left(a: Rect): float32 =
    return a.x

proc right(a: Rect): float32 =
    return a.x + a.w

proc bottom(a: Rect): float32 =
    return a.y

proc intersection(a, b: Rect): Rect =
    let top = min(a.top, b.top)
    let left = max(a.left, b.left)
    let bottom = max(a.bottom, b.bottom)
    let right = min(a.right, b.right)

    return rect(left, bottom, right - left, top - bottom)

proc rect(e: Entity): Rect =
    return rect(e.pos.xy, e.size.xy * 2f)

proc overlaps(a, b: Entity): bool =
    return a.rect.overlaps(b.rect)

proc collide() =
    for a in entities.mitems:
        for b in entities.mitems:
            if a == b:
                # objects shouldn't collide with themselves
                continue

            var i = intersection(a.rect, b.rect)

            if i.w < 0f or i.h < 0f:
                # these being < 0 means they don't intersect
                continue

            let aStatic = a.forces ~= vec3()
            let bStatic = b.forces ~= vec3()

            if aStatic and bStatic:
                # static-to-static is irrelevant
                continue

            if (not aStatic) and (not bStatic):
                # dynamic-to-dynamic not supported
                continue

            # part of the reason why they're one letters is because
            # static is a reserved keyword in Nim
            let s = if aStatic: a else: b
            let d = if bStatic: a else: b

            var iterations = 0

            while s.overlaps(d):
                inc iterations
                assert iterations <= 100, "collision loop has looped over 100 times! stopping to avoid an infinite loop!"

                d.pos -= d.forces * 0.1f

proc update() =
    input()

    player.forces = player.vel + vec3(0f, -0.1f, 0f)
    player.pos += player.forces

    # issue: you're stuck in blocks b/c gravity and velocity get merged
    # solution: apply collisions to individual forces, separately
    collide()

window.onFrame = proc() =
    clear(0f, 0f, 0f, 1f)

    for e in entities:
        let matrix = block:
            let square = rotate(TAU.float32 / 8f, vec3(0f, 0f, 1f))
            let to1x1 = scale(vec3(1f / cos(TAU.float32 / 8f)))
            let notCentered = translate(vec3(1f, 1f, 0f))
            let toWorld = translate(e.pos)
            let sized = scale(e.size)
            let scaled = scale(vec3(scale))

            scaled * toWorld * sized * notCentered * to1x1 * square

        poly(4, vec4(1f - vec3((e.vel + 1f) / 2f), 1f), matrix)

    poly.draw()
    poly.clear()

init()

while not window.closeRequested:
    update()

    window.swapBuffers()
    pollEvents()
