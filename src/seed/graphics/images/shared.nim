import std/[tables, sugar]

type
    Image* = object of RootObj
        data*: seq[uint8]

        width*, height*: uint32
        channels*, colorspace*: uint8

var formats* = initTable[string, File -> Image]()
var transformers* = initTable[string, string -> string]()