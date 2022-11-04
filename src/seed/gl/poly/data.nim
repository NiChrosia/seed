import vmath

proc newPolyVertices*(sides: int): seq[Vec2] =
    let increment = 360f / float32(sides)

    for index in 0 ..< sides:
        let angle = degToRad(increment * float32(index))

        let x = cos(angle)
        let y = sin(angle)

        let v = vec2(x, y)
        result.add(v)

proc newPolyIndices*(sides: int): seq[uint32] =
    for i in 1 .. (uint32(sides) - 2):
        result.add(0)
        result.add(i)
        result.add(i + 1)