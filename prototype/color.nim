## A module providing buffers, sections, and construction procs
## to easily allow creation of colored polygons.

import sections, attributes, vmath, shady

proc processVertex(gl_Position: var Vec4, vColor: var Vec4, pos: Vec2, color: Vec4, layer: float) =
    gl_Position = vec4(pos.x, pos.y, layer, 1f)
    vColor = color

proc processFragment(FragColor: var Vec4, vColor: Vec4) =
    FragColor = vColor

