import std/[macros]

proc echoNode*(node: NimNode) =
    echo node.treeRepr()