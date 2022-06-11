import shared, kinds, buffers, shaders, opengl, tables

type
    # essentially an emulator of bound objects
    Context* = object
        vertexArray: VertexArray
        buffers*: Table[BufferKind, Buffer]
        program: ShaderProgram

# named glContext instead of context because the compiler mistakes it for the module, which is of type void
# annoyingly, it merely says 'undeclared identifier vertexArray', for example, rather than something about invalid types
var glContext* {.global.} = Context()

# binding
template bindObject(item, function: typed) =
    # parameters don't match because keywords aren't contextual, and thus need to be renamed
    if item == nil:
        function(0)
    else:
        function(item.handle)

template bindTypedObject(item, defaultKind, function: typed) = 
    if item == nil:
        function(defaultKind.asEnum, 0)
    else:
        function(item.kind.asEnum, item.handle)

proc `vertexArray=`*(glContext: var Context, array: VertexArray) {.inline.} =
    bindObject(array, glBindVertexArray)
    glContext.vertexArray = array

proc vertexArray*(glContext: Context): VertexArray {.inline.} =
    result = glContext.vertexArray

proc `[]=`*(context: var Context, kind: BufferKind, buffer: Buffer) {.inline.} =
    bindTypedObject(buffer, kind, glBindBuffer)
    context.buffers[kind] = buffer

proc `[]`*(context: Context, kind: BufferKind): Buffer {.inline.} =
    result = context.buffers[kind]

proc `program=`*(glContext: var Context, program: ShaderProgram) {.inline.} =
    bindObject(program, glUseProgram)
    glContext.program = program

proc program*(glContext: Context): ShaderProgram {.inline.} =
    result = glContext.program