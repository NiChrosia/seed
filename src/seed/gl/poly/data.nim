import vmath

## vertices

# optimized shapes

proc newTriVertices*(): seq[Vec2] =
    let increment = 120f.toRadians()

    for index in 1 .. 3:
        let angle = increment * float32(index)

        let x = cos(angle)
        let y = sin(angle)

        let vertex = vec2(x, y)
        result.add(vertex)

proc newRectVertices*(): seq[Vec2] =
    let increment = 90f.toRadians()

    for index in 1 .. 4:
        let angle = increment * float32(index)

        let x = cos(angle)
        let y = sin(angle)

        let vertex = vec2(x, y)
        result.add(vertex)

# equilaterals

# todo: implement fan triangulation
proc newPolyVertices*(sides: int): seq[Vec2] =
    if sides in 3 .. 4:
        if sides == 3:
            return newTriVertices()
        else:
            return newRectVertices()

    let increment = (360f / float32(sides)).toRadians()

    # add a center vertex for indices
    result.add(vec2(0f, 0f))

    for index in 1 .. sides:
        let angle = increment * float32(index)

        let x = cos(angle)
        let y = sin(angle)

        let vertex = vec2(x, y)
        result.add(vertex)

## indices

# optimized shapes

proc newTriIndices*[I](): seq[I] =
    return @[I(0), 1, 2]

proc newRectIndices*[I](): seq[I] =
    return @[
        I(0), 1, 2,
        2, 3, 0
    ]

# equilaterals

# generic number parameter to allow varying precision,
# for the sake of memory efficiency
proc newPolyIndices*[I](sides: I): seq[I] =
    if sides in I(3) .. I(4):
        if sides == I(3):
            return newTriIndices[I]()
        else:
            return newRectIndices[I]()

    let center: I = 0
    let one = I(1)

    for index in one .. sides:
        var nextIndex = index + one
        if nextIndex > sides:
            nextIndex = one

        result.add(center)
        result.add(index)
        result.add(nextIndex)