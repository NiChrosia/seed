import shared, opengl, std/[tables, with]

type
    Shader* = ref object of Handled[uint32]
        kind*: GLenum

    ShaderProgram* = ref object of Handled[uint32]
        vertex, fragment: Shader

    Compiled = Shader or ShaderProgram

type
    CompilationError = object of Defect
    LinkageError = object of Defect

# compilation & linking

# low-level

proc `source=`(shader: Shader, source: string) =
    let stringArray = [source]
    let cStringArray = allocCStringArray(stringArray)

    glShaderSource(shader.handle, 1, cStringArray, nil)

    deallocCStringArray(cStringArray)

proc evaluate[T: Compiled](obj: T, parameter: GLenum): int32 =
    var value: int32

    when T is Shader:
        glGetShaderiv(obj.handle, parameter, addr value)
    elif T is ShaderProgram:
        glGetProgramiv(obj.handle, parameter, addr value)

    return value

proc compileStatus[T: Compiled](obj: T): bool =
    let intResult = when T is Shader:
        evaluate(obj, GL_COMPILE_STATUS)
    elif T is ShaderProgram:
        evaluate(obj, GL_LINK_STATUS)

    return intResult == 1

proc logLength[T: Compiled](obj: T): int32 =
    evaluate(obj, GL_INFO_LOG_LENGTH)

proc log[T: Compiled](obj: T): string =
    let length = logLength(obj)
    let memory = alloc(length + 1) # null-terminated
    let log = cast[cstring](memory)

    when T is Shader:
        glGetShaderInfoLog(obj.handle, length, nil, log)
    elif T is ShaderProgram:
        glGetProgramInfoLog(obj.handle, length, nil, log)

    result = $log

    dealloc(log)

# medium-level

proc compile(shader: Shader) =
    glCompileShader(shader.handle)

    let status = shader.compileStatus()

    if status == false:
        let log = shader.log()
        let message = "Shader compilation failed!" & "\n" & log

        raise newException(CompilationError, message)

proc link*(program: ShaderProgram) =
    glLinkProgram(program.handle)

    let status = program.compileStatus()

    if status == false:
        let log = program.log()
        let message = "Shader program linkage failed!" & "\n" & log
        
        raise newException(LinkageError, message)

# initialization

proc newShader*(kind: GLenum, source: string): Shader = 
    let handle = glCreateShader(kind)

    # it would seem calling `result.property = value` implicitly
    # initializes the result, requiring manual usage when using `with`
    result = new(Shader)

    with(result):
        handle = handle
        kind = kind
        source = source

        compile()

proc newShader*(kind: GLenum, source: File): Shader =
    let contents = readAll(source)
    
    return newShader(kind, contents)

proc newProgram*(): ShaderProgram =
    let handle = glCreateProgram()
    return ShaderProgram(handle: handle)

proc `vertex=`*(program: ShaderProgram, shader: Shader) =
    let function = case shader == nil:
    of true: glDetachShader
    of false: glAttachShader
    
    function(program.handle, shader.handle)
    program.vertex = shader

proc `fragment=`*(program: ShaderProgram, shader: Shader) = 
    let function = case shader == nil:
    of true: glDetachShader
    of false: glAttachShader
    
    function(program.handle, shader.handle)
    program.fragment = shader

proc `shaders=`*(program: ShaderProgram, shaders: tuple[vertex: Shader, fragment: Shader]) =
    # manual invocations to ensure proper handling
    `vertex=`(program, shaders.vertex)
    `fragment=`(program, shaders.fragment)