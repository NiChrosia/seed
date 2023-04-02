import tables
import ../api/rendering/[cameras, atlases]
import staticglfw, vmath

var
    WINDOW_SIZE*: IVec2

    window*: Window
    camera* = Camera3.init()

    keysDown*: Table[int, bool]
    mousePos*: Vec2

    atlas*: Atlas
