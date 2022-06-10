type
    Handled*[H: SomeInteger] = object of RootObj
        handle*: H
        register*: proc(): H

proc register*[H: SomeInteger](function: proc(count: int32, handles: ptr H) {.stdcall.}): H = 
    var handle: H
    function(1, addr handle)
    result = handle