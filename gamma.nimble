# Package

version       = "0.1.0"
author        = "NiChrosia"
description   = "the third installment"
license       = "MIT"
srcDir        = "src"
bin           = @["gamma"]
binDir        = "build"


# Dependencies

requires "nim >= 1.7.3"
requires "opengl >= 1.1.0"
requires "staticglfw >= 4.1.2"
requires "vmath >= 1.2.0"
requires "nimpng >= 0.3.2"
requires "noisy >= 0.4.5"

template shell(args: string) =
    try: exec(args)
    except OSError: quit(1)

task assets, "Packages assets into src/assets.nim.":
    shell "nimassets -d=assets/ -o=src/assets.nim -t=base64"
    shell "sed -i 's/assets: Table/assets*: Table/g' src/assets.nim"
