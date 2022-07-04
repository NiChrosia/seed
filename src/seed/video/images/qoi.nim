import common, qoi_nim/[transcode], std/[with]

proc readQoi*(bytes: seq[byte]): Image =
    let
        (data, desc) = decode(bytes)

        width = desc.width.int
        height = desc.height.int

        channels = desc.channels.int
        colorspace = desc.colorspace.int

    with(result):
        data = data

        size = @[width, height]

        channels = channels
        colorspace = colorspace

proc writeQoi*(image: Image): seq[byte] =
    let
        width = image.width.uint32
        height = image.height.uint32

        channels = image.channels.uint8
        colorspace = image.colorspace.uint8

        desc = QOIDesc(width: width, height: height, channels: channels, colorspace: colorspace)
        image = encode(image.data, desc)

    return image.data