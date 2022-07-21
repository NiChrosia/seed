import macroutils, opengl, std/[macros, strformat]

type
    Field = object
        name: string
        kind: NimNode

    GlslStruct = enum
        normal, vector, matrix

    GlslType = object
        case struct: GlslStruct
        of normal:
            discard
        of vector:
            length: uint32
        of matrix:
            width, height: uint32
        
        kind: GlEnum

    Attribute = object
        index: uint32
        kind: GlslType

proc newNormalType(kind: GlEnum): GlslType =
    return GlslType(struct: normal, kind: kind)

proc newVectorType(length: uint32, kind: GlEnum): GlslType =
    return GlslType(struct: vector, length: length, kind: kind)

proc newMatrixType(width, height: uint32, kind: GlEnum): GlslType =
    return GlslType(struct: matrix, width: width, height: height, kind: kind)

proc indexOf(program: uint32, attribute: string): uint32 =
    # cstring means 'compatible string'
    let compatAttribute = cstring(attribute)
    # plot twist: this can't be run at compile time, so we have to
    # embed code that does it for us
    let index = glGetAttribLocation(program, compatAttribute)

    # for whatever reason, opengl returns a signed int for
    # glGetAttribLocation, but takes an unsigned int for
    # glVertexAttribPointer. Thus the conversion.
    return uint32(index)

proc glTypeOf(typeSymbol: NimNode): GlEnum =
    expectKind typeSymbol, nnkSym

    let name = typeSymbol.strVal()
    return case name
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
        error(fmt"Unrecognized GLSL type '{name}'!")
        0x0.GlEnum

proc arrayAttributes(arrayNode: NimNode): tuple[size: uint32, kind: NimNode] =
    expectKind arrayNode, nnkBracketExpr
    # what arrayNode looks like:
    #   BracketExpr
    #       Sym "array"
    #       BracketExpr
    #           Sym "range"
    #           IntLit 0
    #           IntLit [lastIndex]
    #       Sym "[typeName]"

    let range = arrayNode[1]
    let high = range[2]
        .intVal()
        .uint32()
    let size = high + 1

    let kind = arrayNode[2]

    return (size, kind)

proc glslTypeOf(typeNode: NimNode): GlslType =
    # typeNode looks like this:
    # in the case of an array:
    #   BracketExpr
    #       Sym "array"
    #       BracketExpr
    #           IntLit 0
    #           IntLit [lastIndex]
    #       Sym "[typeName]"
    # otherwise:
    #   Sym "[typeName]"
    echoNode typeNode

    if typeNode.kind == nnkBracketExpr:
        # this is either a vector or a matrix
        let (height, trueTypeNode) = arrayAttributes(typeNode)

        if trueTypeNode.kind == nnkBracketExpr:
            # this is a matrix
            let (width, realTypeNode) = arrayAttributes(trueTypeNode)

            if realTypeNode.kind != nnkSym:
                raise newException(ValueError, "Arrays of depth > 2 are not supported.")

            let kind = glTypeOf(realTypeNode)

            return newMatrixType(width, height, kind)
        else:
            # this is a vector
            let kind = glTypeOf(trueTypeNode)

            return newVectorType(height, kind)
    else:
        # this is a normal
        let kind = glTypeOf(typeNode)

        return newNormalType(kind)

macro configureVertexAttributes(vertexSymbol: typedesc, program: static[uint32], vertices: static[int]): untyped =
    # a typedesc node looks like this:
    #   Sym "[typeName]"
    # thus, we will get the typedesc using getType
    let typedescNode = vertexSymbol.getType()
    # now, we have a typedesc, which looks like:
    #   BracketExpr
    #       Sym "typeDesc"
    #       Sym "[typeName]"
    # however redundant this may look, now we'll call
    # getType again on the type symbol
    let typeSymbol = typedescNode[1]
    let vertexType = typeSymbol.getType()
    # at last, now we have an type, whose tree is:
    #   ObjectTy
    #       Empty
    #       Empty
    #       RecList
    #           Sym "[fieldName]"
    let fieldList = vertexType[2]
    # with access to the type's fields, now we can perform
    # actually useful operations. For convenience, the fields
    # will be converted to a seq[Field], to be used in a pipeline
    # of operations. Eventually, these will be converted into
    # a sequence of attributes (seq[Attribute]), which can
    # then be directly used by glVertexAttribPointer.

    var fields: seq[Field]

    for fieldSymbol in fieldList:
        let name = fieldSymbol.strVal()
        let kind = fieldSymbol.getType()

        let field = Field(name: name, kind: kind)
        fields.add(field)

    var attributes: seq[Attribute]

    for field in fields:
        let index = program.indexOf(field.name)
        let kind = glslTypeOf(field.kind)

        let attribute = Attribute(index: index, kind: kind)
        attributes.add(attribute)

    echo attributes
    
type
    MyVertex = object
        pos: array[2, float32]

const program: uint32 = 0
configureVertexAttributes(MyVertex, program, vertices = 4)