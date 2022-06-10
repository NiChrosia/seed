import types, kinds, opengl

# initialization

proc newShader*(kind: ShaderKind): Shader = 
    let handle = glCreateShader(kind.asEnum)
    result = Shader(handle: handle, kind: kind)

proc newVertexShader*(): Shader =
    result = newShader(vertexShader)

proc newFragmentShader*(): Shader =
    result = newShader(fragmentShader)

# TODO implement immediate vertex & fragment shader attachment
# and immediate shader compilation & linking
proc newProgram*(): ShaderProgram =
    let handle = glCreateProgram()
    result = ShaderProgram(handle: handle)