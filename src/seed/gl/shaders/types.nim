import opengl

type
    # errors
    CompilationFailure* = object of Defect
    LinkingFailure* = object of Defect

    ReleasePerformanceDefect* = object of Defect

    # kinds
    ShaderKind* = enum
        sFragment = GL_FRAGMENT_SHADER,
        sVertex = GL_VERTEX_SHADER,

    # objects
    Shader* = distinct uint32
    ShaderProgram* = distinct uint32

    UniformLocation* = distinct int32

proc `*`*(shader: Shader or ShaderProgram): uint32 =
    ## A shorthand for getting the handle of 
    ## a shader or program

    return shader.uint32