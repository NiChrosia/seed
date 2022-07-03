import std/[tables, hashes]

var activity = newTable[int, bool]([])

proc active*[T](itemType: typedesc[T]): bool =
    let name = $itemType
    let key = hash(name)

    return activity[key]

proc `active=`*[T](itemType: typedesc[T], value: bool) =
    let name = $itemType
    let key = hash(name)

    activity[key] = value