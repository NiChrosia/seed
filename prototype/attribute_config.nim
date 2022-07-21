import vmath, shady, windy, opengl, std/[macros, genasts, strformat]

type
    # distinct types cannot be used otherwise it dies
    # thus, an alternative, cursed type was introduced
    AltGlEnum = uint32
    
    Attribute = object
        name: string
        kind: AltGlEnum
    
        offset: int32
    
        length: int32
        indexOffset: int
    
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

proc attribPtr(index: uint32, altKind: AltGlEnum, length, offset, stride: int32) =
    let kind = GlEnum(altKind)

    glVertexAttribPointer(index, length, kind, false, stride, cast[pointer](offset))

proc length(arrayNode: NimNode): int =
    let rangeNode = arrayNode[1]
    let highNode = rangeNode[2]
    let high = highNode.intVal()
    
    return int(high) + 1

proc addAttribute(attributes: var seq[Attribute], name: string, kind: AltGlEnum, offset: int32) =
    var attribute = Attribute()
    attribute.name = name
    attribute.kind = kind
    attribute.offset = offset
    attribute.length = 1
    
    attributes.add(attribute)

proc addVector(attributes: var seq[Attribute], name: string, kind: AltGlEnum, offset: int32, height: int32) =
    var attribute = Attribute()
    attribute.name = name
    attribute.kind = kind
    attribute.offset = offset
    attribute.length = height
    
    attributes.add(attribute)

proc addMatrix(attributes: var seq[Attribute], name: string, kind: AltGlEnum, offset: int32, width, height: int32) =
    for indexOffset in 0 ..< height:
        var attribute = Attribute()
        attribute.name = name
        attribute.kind = kind
        attribute.offset = offset
        attribute.length = width
        attribute.indexOffset = indexOffset
        
        attributes.add(attribute)

macro declareVertexPointers(vertex: typedesc, program: uint): untyped =
    let typeNode = vertex.getType()[1].getType()
    let fields = typeNode[2]
    
    var attributes: seq[Attribute]
    
    for field in fields:
        let name = field.strVal()
        let fieldOffset = int32(field.getOffset())
        let fieldTypeNode = field.getType()
        
        if fieldTypeNode.kind == nnkBracketExpr:
            let height = int32(fieldTypeNode.length())
            let trueTypeNode = fieldTypeNode[2]
            
            if trueTypeNode.kind == nnkBracketExpr:
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

            attribPtr(index, a.kind, a.length, a.offset, vertexSize)

type
    Vertex = object
        position: array[2, float32]

proc vertex(gl_Position: var Vec4, vPos: var Vec4, position: Vec2) =
    gl_Position = vec4(vec3(position, 0f), 0f)
    vPos = gl_Position

proc fragment(FragColor: var Vec4, vPos: Vec4) =
    FragColor = vPos

let window = newWindow("Test", ivec2(800, 600), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

var
    vertexSource = toGLSL(vertex, "330", "")
    fragmentSource = toGLSL(fragment, "330", "")

var
    vertexShader = glCreateShader(GlVertexShader)
    fragmentShader = glCreateShader(GlFragmentShader)

var sourceArray: cstringArray

sourceArray = allocCStringArray([vertexSource])
glShaderSource(vertexShader, 1, sourceArray, nil)
deallocCStringArray(sourceArray)

sourceArray = allocCStringArray([fragmentSource])
glShaderSource(fragmentShader, 1, sourceArray, nil)
deallocCStringArray(sourceArray)

glCompileShader(vertexShader)
glCompileShader(fragmentShader)

var program = glCreateProgram()

glAttachShader(program, vertexShader)
glAttachShader(program, fragmentShader)

glLinkProgram(program)

var vertexArray: uint32
glGenVertexArrays(1, addr vertexArray)

declareVertexPointers(Vertex, program)