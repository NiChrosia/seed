type
    Image* = object
        data*: seq[byte]
        size*: seq[int]

        channels*, colorspace*: int


template declareDimension(name: untyped, position: int) =
    proc `name`*(image: Image): int {.inject.} =
        return image.size[position]


declareDimension(width, 0)
declareDimension(height, 1)
declareDimension(depth, 2)