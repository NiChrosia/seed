# credits to https://github.com/JohnnyonFlame/texture-atlas for the logic

type
    Rect* = ref object
        left*, right*, top*, bottom*: int

    FloatRect* = object
        left*, right*, bottom*, top*: float

    VirtualTexture* = ref object
        rect: Rect
        invalidated: bool

    VirtualAtlas* = ref object
        holes: seq[Rect]
        textures: seq[VirtualTexture]

        holesInvalidated: bool

        dimensions*, padding*: int

# private
# - rects
proc new(_: typedesc[Rect], left, right, top, bottom: int): Rect =
    result = new(Rect)
    
    result.left = left
    result.right = right
    result.top = top
    result.bottom = bottom

proc width*(rect: Rect): int =
    return rect.right - rect.left

proc height*(rect: Rect): int =
    return rect.top - rect.bottom

proc area(rect: Rect): int =
    return rect.width * rect.height

proc overlaps(a, b: Rect): bool =
    return (a.right > b.left and a.left < b.right) and
           (a.top > b.bottom and a.bottom < b.top)

proc contains(parent, child: Rect): bool =
    ## whether parent fully contains child
    
    return (child.left >= parent.left and child.right <= parent.right) and
           (child.top <= parent.top and child.bottom >= parent.bottom)

# - holes
proc resetHoles(atlas: var VirtualAtlas) =
    let first = Rect.new(0, atlas.dimensions, atlas.dimensions, 0)
    atlas.holes = @[first]

proc splitHoles(atlas: var VirtualAtlas, cut: Rect) =
    for i in 0 .. atlas.holes.high:
        let hole = atlas.holes[i]

        if not hole.overlaps(cut):
            continue

        # left, right, up, down
        var newHoles = [
            Rect.new(hole.left, cut.left, hole.top, hole.bottom),
            Rect.new(cut.right, hole.right, hole.top, hole.bottom),
            Rect.new(hole.left, hole.right, hole.top, cut.top),
            Rect.new(hole.left, hole.right, cut.bottom, hole.bottom),
        ]

        atlas.holes.del(i)

        for newHole in newHoles:
            if newHole.area == 0:
                continue

            atlas.holes.add(newHole)

        var a = 0
        var b = a + 1

        while a < atlas.holes.len:
            while b < atlas.holes.len:
                if atlas.holes[a].contains(atlas.holes[b]):
                    atlas.holes.del(b)

                    # recheck b
                    b -= 1
                elif atlas.holes[b].contains(atlas.holes[a]):
                    atlas.holes.del(a)

                    # restart the loop
                    b = a + 1

                b += 1
            a += 1

# - textures
proc lookupBestFit(atlas: VirtualAtlas, width, height: int): Rect =
    ## searches for the hole with the least area while fitting
    ## width and height, thus being the best fit

    var best: Rect
    var bestArea = int.high

    for hole in atlas.holes:
        if hole.width < width or hole.height < height:
            continue

        let area = hole.area
        if area < bestArea:
            best = hole
            bestArea = area

    assert best != nil, "no fit found!"

    return best

# public
# - rects
proc x*(rect: Rect): int =
    return rect.left

proc y*(rect: Rect): int =
    return rect.bottom

# - atlas
proc new*(_: typedesc[VirtualAtlas], dimensions, padding: int): VirtualAtlas =
    result = new(VirtualAtlas)

    result.dimensions = dimensions
    result.padding = padding

    result.resetHoles()

# - textures
proc newTexture*(atlas: var VirtualAtlas): VirtualTexture =
    result = new(VirtualTexture)
    result.rect = new(Rect)
    result.invalidated = false

proc destroyTexture*(atlas: var VirtualAtlas, texture: var VirtualTexture) =
    texture.invalidated = true
    atlas.holesInvalidated = true

proc allocate*(atlas: var VirtualAtlas, texture: var VirtualTexture, rawWidth, rawHeight: int) =
    if atlas.holesInvalidated:
        atlas.holesInvalidated = false
        atlas.resetHoles()

        var i = 0
        while i < atlas.textures.len:
            var candidate = atlas.textures[i]

            if candidate.invalidated:
                if candidate.rect.area == 0:
                    continue

                atlas.splitHoles(candidate.rect)
            else:
                atlas.textures.del(i)

                # retry index
                i -= 1

    let width = rawWidth + atlas.padding * 2
    let height = rawHeight + atlas.padding * 2

    let bestFit = atlas.lookupBestFit(width, height)

    let vtex = Rect.new(bestFit.left, bestFit.left + width, bestFit.bottom + height, bestFit.bottom)

    texture.rect = vtex
    atlas.splitHoles(texture.rect)

proc coords*(atlas: VirtualAtlas, texture: VirtualTexture, includingPadding: bool = false): Rect =
    result = new(Rect)
    result[] = texture.rect[]

    if not includingPadding:
        result.left += atlas.padding
        result.bottom += atlas.padding
        result.right -= atlas.padding * 2
        result.top -= atlas.padding * 2

proc normCoords*(atlas: VirtualAtlas, texture: VirtualTexture, includingPadding: bool = false): FloatRect =
    ## returns x, y, w, and h in normalized (0-1) texture coordinates

    let onAtlas = atlas.coords(texture, includingPadding)

    result.left   = onAtlas.left.float   / atlas.dimensions.float
    result.right  = onAtlas.right.float  / atlas.dimensions.float
    result.bottom = onAtlas.bottom.float / atlas.dimensions.float
    result.top    = onAtlas.top.float    / atlas.dimensions.float
