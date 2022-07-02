import common, std/[with, sugar]

type
    ImageReader* = (bytes: seq[byte]) -> Image
    ImageWriter* = (image: Image) -> seq[byte]

    ImageFormat* = object
        read*: ImageReader
        write*: ImageWriter


# initialization

proc newFormat*(read: ImageReader, write: ImageWriter): ImageFormat =
    with(result):
        read = read
        write = write

# utility

proc bytes*(file: File): seq[byte] =
    let string = readAll(file)
    return cast[seq[byte]](string)

# io

proc read*(file: File, format: ImageFormat): Image =
    let bytes = file.bytes()

    return format.read(bytes)

proc write*(destination: File, format: ImageFormat, image: Image) =
    let bytes = format.write(image)

    let string = cast[string](bytes)

    destination.write(string)

# io