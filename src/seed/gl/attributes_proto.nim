import strutils

var nextId = 0

proc activeProgram(): int = 0

proc index(name: string, program: int = activeProgram()): int =
  result = nextId
  nextId += 1

proc size(base: string): int =
  return 4

proc attribute(index: int, base: string, components: int, offset, size, stride: int) =
  echo "attribute(", index, ", ", base, ", ", components, ", ", offset, ", ", size, ", ", stride, ")"

proc attributes(code: string) =
  var attributes: seq[tuple[name: string, base: string, components, columns: int]]
  var stride: int
  
  for line in code.split("\n"):
    if line == "":
      continue
    
    let noSpaces = line.replace(" ", "")
    let parts = noSpaces.split("=")
    
    let name = parts[0]
    var types = parts[1].split(".")
    
    let base = types[0]
    
    # default is 1
    while types.len <= 3:
      types.add("1")
    
    let components = parseInt(types[1])
    let columns = parseInt(types[2])
    
    attributes.add((name, base, components, columns))
    stride += size(base) * components * columns
    
    echo name, ": ", types
  
  var offset: int
  
  for a in attributes:
    let baseIndex = index(a.name)
    let size = a.components * a.base.size()
    
    if a.columns > 1:
      # matrix
      for column in 0 ..< a.columns:
        let currentOffset = offset + (column * a.components * a.base.size())
        let index = baseIndex + column
        
        attribute(index, a.base, a.components, currentOffset, size, stride)
    elif a.components > 1:
      # vector
      attribute(baseIndex, a.base, a.components, offset, size, stride)
    else:
      # scalar
      attribute(baseIndex, a.base, 1, offset, size, stride)
    
    offset += a.base.size() * a.components * a.columns

# uses the currently bound VA, P, and B

#[
attributes """
something = int
position = float.2
color = float.4
model = float.4.4
"""

# no way I actually wrote this
# how about, instead, this?

attributes """
layout (location = 0) flat in int something;
layout (location = 1) in vec2 position;
layout (location = 2) in vec4 color;
layout (location = 3) in mat4 model;
"""

# or have it literally just process the shader source instead
]#
