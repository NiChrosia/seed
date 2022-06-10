import shared, kinds, configuration, buffers, shaders, opengl, tables

type
    # essentially an emulator of bound objects
    Context = object
        vertexArray: ref VertexArray
        buffers: Table[BufferKind, ref Buffer]
        program: ref ShaderProgram

var context* {.global.} = Context()

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

# getter & setter declaration
template declareProperty(name: untyped, itemType, bindFunction: typed) = 
    proc `name =`*(context: var Context, item: itemType) {.inject.} = 
        bindObject(item, bindFunction)
        context.`name` = item

    proc `name`*(context: Context): itemType = 
        result = context.`name`

template declareTypedProperty(name, plural: untyped, itemType, defaultKind, bindFunction: typed) = 
    proc `name =`*(context: var Context, item: itemType) {.inject.} = 
        bindTypedObject(item, defaultKind, bindFunction)
        context.`plural`[defaultKind] = item

    proc `name`*(context: Context): itemType = 
        result = context.`plural`[defaultKind]

# specific property types, generally for typed properties, like buffers & textures
# speaking of which, TODO implement textures
template declareBufferProperty(name: untyped, defaultKind: typed) = 
    declareTypedProperty(name, buffers, ref Buffer, defaultKind, glBindBuffer)

# getters & setters
declareProperty(vertexArray, ref VertexArray, glBindVertexArray)

declareBufferProperty(vertexBuffer, BufferKind.vertexBuffer)
declareBufferProperty(elementBuffer, BufferKind.elementBuffer)

declareProperty(program, ref ShaderProgram, glUseProgram)