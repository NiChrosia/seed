import os, strutils, tables, strformat
import ../atlases, ../../assets
import nimPNG, vmath

type
    Pixel* = object
        r*, g*, b*, a*: uint8

    Image* = object
        width*, height*: int32
        data*: seq[Pixel]

var atlas: VirtualAtlas
var textures: Table[string, VirtualTexture]

var image: Image

proc setup*(dimensions: int32) =
    atlas = VirtualAtlas.new(dimensions, 0)
    image = Image(width: dimensions, height: dimensions, data: newSeq[Pixel](dimensions * dimensions))

    for path in assets.assets.keys:
        let (dir, name, ext) = splitFile(path)

        if dir != "assets/sprites" or ext.toLower() != ".png":
            continue

        var textureImage = decodePNG32(getAssetToStr(path))

        var texture = atlas.newTexture()
        atlas.allocate(texture, textureImage.width, textureImage.height)

        var coordRect = atlas.coords(texture)

        for y in coordRect.bottom ..< coordRect.top:
            copyMem(addr image.data[y * dimensions + coordRect.left], addr textureImage.data[(y - coordRect.bottom) * textureImage.height], coordRect.width * 4)

            # for x in coordRect.left ..< coordRect.right:
            #     let textureX = x - coordRect.left
            #     let textureY = y - coordRect.bottom

            #     let pixelIndex = textureY * textureImage.height + textureX

            #     let r = cast[uint8](textureImage.data[pixelIndex * 4 + 0])
            #     let g = cast[uint8](textureImage.data[pixelIndex * 4 + 1])
            #     let b = cast[uint8](textureImage.data[pixelIndex * 4 + 2])
            #     let a = cast[uint8](textureImage.data[pixelIndex * 4 + 3])

            #     image.data[y * dimensions + x] = Pixel(r: r, g: g, b: b, a: a)

        textures[name] = texture

proc coords*(name: string, normalized: Vec2): Vec2 =
    ## converts texture-specific normalized coordinates interop
    ## normalized atlas coordinates

    if not textures.hasKey(name):
        raise Exception.newException(fmt"Texture '{name}' does not exist!")

    # todo: make the atlas algorithm outputs be more conveniently usable.
    # ie, make them use stuff like vec2 and have proper rect types
    let coordRect = atlas.coords(textures[name])

    var pos = vec2(ivec2(coordRect.left.int32, coordRect.bottom.int32))
    var size = vec2(ivec2(coordRect.right.int32 - coordRect.left.int32, coordRect.top.int32 - coordRect.bottom.int32))

    pos += 0.5f
    size -= 1f

    var normPos = pos / float(atlas.dimensions)
    var normSize = size / float(atlas.dimensions)

    return normPos + normSize * normalized

proc getImage*(): Image =
    return image
