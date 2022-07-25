import vmath, shady, windy, opengl, std/[macros, genasts, strformat, times, terminal], ../src/seed/video/backends/gl/shaders

type
    Vector*[height: static[int], T] = array[height, T]
    Matrix*[width, height: static[int], T] = array[width * height, T]
    SquareMatrix*[width: static[int], T] = Matrix[width, width, T]

proc getGlTypeFor(name: string): uint32 =
    let asEnum = case name
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
        error(fmt"Unrecognized GL type '{name}'!")
        GL_INVALID_ENUM

    return uint32(asEnum)

proc attributePointer(index: uint32, kind: uint32, offset, length, stride: int32, instanced: bool) =
    glEnableVertexAttribArray(index)
    glVertexAttribPointer(index, length, GlEnum(kind), false, stride, cast[pointer](offset))

    if instanced:
        glVertexAttribDivisor(index, 1)

proc attributePointerCall(
    program: NimNode, 
    name: string, 
    kind: uint32, 
    offset, length, stride: int32, 
    indexOffset: uint32,
    instanced: NimNode
): NimNode =
    result = genAst(program, name, kind, offset, length, stride, indexOffset, instanced) do:
        let cName = cstring(name)

        let index = glGetAttribLocation(program, cName)
        let uIndex = uint32(index) + indexOffset
        
        attributePointer(uIndex, kind, offset, length, stride, instanced)

macro declareAttributes(program: uint32, attributeRepr: typedesc, instanced: bool = false): untyped =
    # a typedesc looks like this
    #   Sym "[type name]"

    # we need to get the type, so
    # we'll first get the typedesc
    # node
    let typedescNode = attributeRepr.getType()
    # now, we have a typedesc node
    # which looks like this:
    #   BracketExpr
    #       Sym "typeDesc"
    #       Sym "[type name]"
    # now we can actually get the type
    let typeSymbol = typedescNode[1]
    let typeNode = typeSymbol.getType()
    # now we have a definition of
    # the type we've been given
    # it should look like this:
    #[
        ObjectTy
            Empty
            Empty
            RecList
                Sym "[field name]"
    ]#
    # now, for the processing, we need the fields,
    # and the result to be a statement list
    let fields = typeNode[2]
    result = newStmtList()

    let typeSize = int32(typeSymbol.getSize())

    for fieldSymbol in fields:
        let fieldName = fieldSymbol.strVal()
        let fieldType = fieldSymbol.getTypeInst()

        let fieldOffset = int32(fieldSymbol.getOffset())

        case fieldType.kind
        of nnkSym:
            let glTypeName = fieldType.strVal()
            let glType = getGlTypeFor(glTypeName)

            result.add attributePointerCall(program, fieldName, glType, fieldOffset, 1, typeSize, 0, instanced)
        of nnkBracketExpr:
            # now we have a type that looks like this:
            #     BracketExpr
            #         [outer type]
            #         [inner type(s)]
            let outerType = fieldType[0]
            let outerName = outerType.strVal()

            case outerName
            of "Matrix":
                # a matrix type looks like:
                #     BracketExpr
                #         Sym "Matrix"
                #         IntLit [width]
                #         IntLit [height]
                #         Sym "[gl type]"
                let width = int32(fieldType[1].intVal())
                let height = uint32(fieldType[2].intVal())

                let glTypeNode = fieldType[3]
                let glTypeName = glTypeNode.strVal()
                let glType = getGlTypeFor(glTypeName)

                let glTypeSize = int32(glTypeNode.getSize())

                for indexOffset in 0 ..< height:
                    let offset = fieldOffset + glTypeSize * width * int32(indexOffset)

                    result.add attributePointerCall(program, fieldName, glType, offset, width, typeSize, indexOffset, instanced)
            of "SquareMatrix":
                # this type looks much the same,
                # albeit with only one int literal,
                # which is the width and height
                let width = int32(fieldType[1].intVal())

                let glTypeNode = fieldType[2]
                let glTypeName = glTypeNode.strVal()
                let glType = getGlTypeFor(glTypeName)

                let glTypeSize = int32(glTypeNode.getSize())

                for indexOffset in 0 ..< uint32(width):
                    let offset = fieldOffset + glTypeSize * width * int32(indexOffset)

                    result.add attributePointerCall(program, fieldName, glType, offset, width, typeSize, indexOffset, instanced)
            of "Vector":
                # and a vector type looks like
                #     BracketExpr
                #         Sym "Vector"
                #         IntLit [height]
                #         Sym "[gl type]"
                let height = int32(fieldType[1].intVal())

                let glTypeName = fieldType[2].strVal()
                let glType = getGlTypeFor(glTypeName)

                result.add attributePointerCall(program, fieldName, glType, fieldOffset, height, typeSize, 0, instanced)
        else:
            error("Unrecognized attribute type!", fieldType)


# -------------------------------------

type
    Vertex = object
        position: Vector[2, float32]
        color: Vector[4, float32]

    Triangle = object
        transform: SquareMatrix[4, float32]

let window = newWindow("Test", ivec2(800, 600), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

var
    vertexShader = newShader(GlVertexShader, """#version 330

in vec2 position;
in vec4 color;
in mat4 transform;

out vec4 vColor;

void main() {
    gl_Position = transform * vec4(vec3(position, 0.0), 1.0);
    vColor = color;
}
""")
    fragmentShader = newShader(GlFragmentShader, """#version 330

in vec4 vColor;

out vec4 FragColor;

void main() {
    FragColor = vColor;
}
""")

    program = newProgram()

program.shaders = (vertexShader, fragmentShader)
program.link()

proc vertex(x, y: float32, color: array[4, float32]): Vertex =
    return Vertex(position: [x, y], color: color)

var vertices = [
    vertex(-1f, -1f, [0f, 0f, 1f, 1f]),
    vertex(-1f,  1f, [0f, 0f, 0f, 1f]), 
    vertex( 1f, -1f, [0f, 0f, 0f, 1f]),
    vertex( 1f,  1f, [0f, 0f, 1f, 1f])
]

var instanceData = translate(vec3(-0.5f, 0f, 0f)) * scale(vec3(0.5f, 0.5f, 1f))

var indices = [
    uint32(0), 1, 2,
    1, 2, 3
]

var vertexArray: uint32
glGenVertexArrays(1, addr vertexArray)

var vertexBuffer, elementBuffer, instanceBuffer: uint32
glGenBuffers(1, addr vertexBuffer)
glGenBuffers(1, addr elementBuffer)
glGenBuffers(1, addr instanceBuffer)

glBindVertexArray(vertexArray)

glBindBuffer(GlArrayBuffer, vertexBuffer)
glBufferData(GlArrayBuffer, sizeof(vertices), addr vertices[0], GL_STATIC_DRAW)

declareAttributes(program.handle, Vertex)

glBindBuffer(GlArrayBuffer, instanceBuffer)
glBufferData(GlArrayBuffer, sizeof(Mat4), addr instanceData[0, 0], GL_STATIC_DRAW)

declareAttributes(program.handle, Triangle, true)

glBindBuffer(GlElementArrayBuffer, elementBuffer)
glBufferData(GlElementArrayBuffer, sizeof(indices), addr indices[0], GL_STATIC_DRAW)

while not window.closeRequested:
    glClearColor(0.2f, 0.3f, 0.3f, 1f)
    glClear(GL_COLOR_BUFFER_BIT)

    glUseProgram(program.handle)
    glBindVertexArray(vertexArray)

    glDrawElementsInstanced(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nil, 1)

    window.swapBuffers()
    pollEvents()