import shared, qoi, std/[os, tables]

formats[".qoi"] = readQoi
transformers[".png"] = pngToQoi

proc openImage*(path: string): Image =
    let file = open(path)
    var (_, _, ext) = splitFile(path)

    if transformers.hasKey(ext):
        let transform = transformers[ext]
        let newPath = transform(path)

        let newFile = open(newPath)
        let (_, _, newExt) = splitFile(newPath)

        let toImage = formats[newExt]
        return newFile.toImage()

    let toImage = formats[ext]
    result = file.toImage()