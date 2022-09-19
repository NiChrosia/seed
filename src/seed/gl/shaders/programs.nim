import opengl

import types, queries/programs

type
    Program = ShaderProgram

# shaders
proc attach*(program: Program, shader: Shader) =
    glAttachShader(*program, *shader)

proc detach*(program: Program, shader: Shader) =
    glDetachShader(*program, *shader)

# linking
proc link*(program: Program) =
    glLinkProgram(*program)

proc check*(program: Program) =
    ## Asserts whether the program linked
    ## successfully, with an exception if
    ## it fails.
    
    if not program.didLink:
        raise newException(LinkingFailure, program.log)

# usage
proc use*(program: Program) =
    glUseProgram(*program)

# lifetime
proc delete*(program: Program) =
    glDeleteProgram(*program)

proc initProgram*(): Program =
    result = Program(glCreateProgram())

proc initProgram*(shaders: openArray[Shader], check: bool): Program =
    ## More concise program initialization.

    result = initProgram()

    for shader in shaders:
        result.attach(shader)

    result.link()

    if check:
        result.check()