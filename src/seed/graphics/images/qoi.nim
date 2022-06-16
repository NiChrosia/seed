import shared, qoi_nim/[conv, transcode], std/[with, os]

proc readQoi*(file: File): Image =
    let size = getFileSize(file)
    var bytes = newSeq[uint8](size)
    let read = readBytes(file, bytes, 0, size)

    if read != size:
        raise newException(IOError, "Did not read entire file!")

    let (data, desc) = decode(bytes)

    with(result):
        data = data

        # making the width & height be unsigned is simply ridiculous
        width = desc.width.int32
        height = desc.height.int32

        channels = desc.channels
        colorspace = desc.colorspace

proc pngToQoi*(path: string): string =
    let (dir, name, _) = splitFile(path)
    result = dir / name & ".qoi"

    convert(path, result)