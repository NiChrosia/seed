import macroutils, vmath, shady, windy, opengl, std/[macros, genasts, strformat], ../src/seed/video/backends/gl/shaders

type
    # distinct types cannot be used otherwise it dies
    # thus, an alternative, cursed type was introduced
    AltGlEnum = uint32
    
    Attribute = object
        name: string
        kind: AltGlEnum
    
        offset: int32
    
        length: int32
        indexOffset: uint32
    
proc kindOf(symbol: NimNode, fieldNode: NimNode): AltGlEnum =
    let name = symbol.strVal()
    let normalEnum = case name
    of "int8":
        cGL_BYTE
    of "int16":
        cGL_SHORT
    of "int32":
        cGL_INT
    of "uint8":
        GL_UNSIGNED_BYTE
    of "uint16":
        GL_UNSIGNED_SHORT
    of "uint32":
        GL_UNSIGNED_INT
    of "float32":
        cGL_FLOAT
    of "float64":
        cGL_DOUBLE
    else:
        let fieldName = fieldNode.strVal()

        error(fmt"Type '{name}' of field '{fieldName}' is not a recognized GL type!", fieldNode)
        GL_INVALID_VALUE

    return AltGlEnum(normalEnum)

proc indexOf(program: uint32, name: string): uint32 =
    let cName = cstring(name)
    let intLocation = glGetAttribLocation(program, cName)

    return uint32(intLocation)

proc attributePointer(index: uint32, altKind: AltGlEnum, length, offset, stride: int32) =
    let kind = GlEnum(altKind)

    glVertexAttribPointer(index, length, kind, false, stride, cast[pointer](offset))

proc length(arrayNode: NimNode): int =
    let rangeNode = arrayNode[1]
    let highNode = rangeNode[2]
    let high = highNode.intVal()
    
    return int(high) + 1

proc addAttribute(attributes: var seq[Attribute], name: string, kind: AltGlEnum, offset: int32) =
    var attribute = Attribute()
    attribute.assign(name, kind, offset)
    attribute.length = 1
    
    attributes.add(attribute)

proc addVector(attributes: var seq[Attribute], name: string, kind: AltGlEnum, offset: int32, height: int32) =
    var attribute = Attribute()
    attribute.assign(name, kind, offset)
    attribute.length = height
    
    attributes.add(attribute)

proc addMatrix(attributes: var seq[Attribute], name: string, kind: AltGlEnum, offset: int32, width, height: int32) =
    for indexOffset in 0 ..< uint32(height):
        var attribute = Attribute()
        attribute.assign(name, kind, offset, indexOffset)
        attribute.length = width
        
        attributes.add(attribute)

macro declareVertexPointers(vertex: typedesc, program: uint): untyped =
    # typedesc symbol (vertex):
    #[
        Sym "[type name]"
    ]#
    # typedesc node (vertex.getType()):
    #[
        Something
            Sym "typeDesc"
            Sym "[type name]"
    ]#
    # type node (vertex.getType()[1].getType()):
    #[
        ObjectTy
            Empty
            Empty
            RecList
                Sym "[field name]"
    ]#

    let typeNode = vertex.getType()[1].getType()
    let fields = typeNode[2]
    
    var attributes: seq[Attribute]
    
    for field in fields:
        let name = field.strVal()
        let fieldOffset = int32(field.getOffset())
        let fieldTypeNode = field.getType()
        
        if fieldTypeNode.kind == nnkBracketExpr:
            # bracket expression node:
            #[
                BracketExpr
                    Sym "[outer]"
                    Sym "[inner]"
            ]#
            if fieldTypeNode[0].strVal() != "array":
                error("Non-array bracketed types are not currently supported.", field)

            let height = int32(fieldTypeNode.length())
            let trueTypeNode = fieldTypeNode[2]
            
            if trueTypeNode.kind == nnkBracketExpr:
                if trueTypeNode[0].strVal() != "array":
                    error("Non-array nested bracketed types are not currently supported.", field)

                let width = int32(trueTypeNode.length())
                let realTypeNode = trueTypeNode[2]
                
                let kind = kindOf(realTypeNode, field)
                
                attributes.addMatrix(name, kind, fieldOffset, width, height)
            else:
                let kind = kindOf(trueTypeNode, field)
                
                attributes.addVector(name, kind, fieldOffset, height)
        else:
            let kind = kindOf(fieldTypeNode, field)
            
            attributes.addAttribute(name, kind, fieldOffset)
    
    let platformVertexSize = vertex.getSize()
    let vertexSize = int32(platformVertexSize)

    result = genAst(attributes, program, vertexSize) do:
        for a in attributes:
            let index = program.indexOf(a.name)

            attributePointer(index + a.indexOffset, a.kind, a.length, a.offset, vertexSize)
            # seriously, why does this function exist
            glEnableVertexAttribArray(index)

type
    Vertex = object
        position: array[3, float32]

proc vertex(gl_Position: var Vec4, vColor: var Vec4, position: Vec3) =
    gl_Position = vec4(position, 1f)
    vColor = vec4(position.xyx, 1f)

proc fragment(FragColor: var Vec4, vColor: Vec4) =
    FragColor = vColor

let window = newWindow("Test", ivec2(800, 600), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

var
    vertexShader = newShader(GlVertexShader, toGLSL(vertex))
    fragmentShader = newShader(GlFragmentShader, toGLSL(fragment))

    program = newProgram()

program.shaders = (vertexShader, fragmentShader)
program.link()

proc vertex(x, y, z: float32): Vertex =
    return Vertex(position: [x, y, z])

var vertices = [
    vertex(-1f, -1f, 0f),
    vertex(-1f,  1f, 0f),
    vertex( 1f, -1f, 0f),
    vertex( 1f,  1f, 0f)
]

var indices = [
    uint32(0), 1, 2,
    1, 2, 3
]

var vertexArray: uint32
glGenVertexArrays(1, addr vertexArray)

var vertexBuffer, elementBuffer: uint32
glGenBuffers(1, addr vertexBuffer)
glGenBuffers(1, addr elementBuffer)

glBindVertexArray(vertexArray)

glBindBuffer(GlArrayBuffer, vertexBuffer)
glBufferData(GlArrayBuffer, sizeof(vertices), addr vertices[0], GL_STATIC_DRAW)

glBindBuffer(GlElementArrayBuffer, elementBuffer)
glBufferData(GlElementArrayBuffer, sizeof(indices), addr indices[0], GL_STATIC_DRAW)

declareVertexPointers(Vertex, program.handle)

while not window.closeRequested:
    glClearColor(0.2f, 0.3f, 0.3f, 1f)
    glClear(GL_COLOR_BUFFER_BIT)

    glUseProgram(program.handle)
    glBindVertexArray(vertexArray)

    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nil)

    window.swapBuffers()
    pollEvents()