import vmath

proc newPolyVertices*(sides: int): seq[Vec2] =
    let increment = TAU / float32(sides)

    for index in 0 ..< sides:
        let angle = increment * float32(index)

        let x = cos(angle)
        let y = sin(angle)

        let v = vec2(x, y)
        result.add(v)

proc newPolyIndices*(sides: int): seq[uint32] =
    for i in 0 ..< uint32(sides):
        result.add(i)