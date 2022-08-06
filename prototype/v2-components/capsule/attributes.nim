import ../core/vertex_arrays, ../core/shaders

import opengl

import std/[macros, genasts]

# internal

# - formatting

type
    Vec*[H: static[int]; T] = array[H, T]
    Mat*[W, H: static[int]; T] = array[W * H, T]

    AttributeType = enum
        scalar, vector, matrix

proc formatScalar*(
    program: NimNode, 
    name: string, offset: int32, dataKind: GlEnum,
    stride: int32
): NimNode =
    let altType = uint32(dataKind)

    result = genAst(program, name, offset, altType, stride) do:
        let index = program.newAttributeIndex(name)

        setScalar(index, GlEnum(altType), offset, stride)

proc formatVector*(
    program: NimNode, 
    name: string, height: int32, offset: int32, dataKind: GlEnum, 
    stride: int32, 
): NimNode =
    let altType = uint32(dataKind)

    result = genAst(program, name, offset, height, altType, stride) do:
        let index = program.newAttributeIndex(name)

        setVector(index, GlEnum(altType), offset, height, stride)

proc formatMatrix*(
    program: NimNode, 
    name: string, width, height: int32, offset: int32, dataKind: GlEnum, 
    stride: int32, 
): NimNode =
    let altType = uint32(dataKind)

    result = genAst(program, name, offset, width, height, altType, stride) do:
        let index = program.newAttributeIndex(name)

        setMatrix(index, GlEnum(altType), offset, width, height, stride)

# types

proc getAttributeType(typeNode: NimNode): AttributeType =
    if typeNode.kind == nnkIdent or typeNode.kind == nnkSym:
        return scalar
    elif typeNode.kind == nnkBracketExpr:
        let outer = $typeNode[0]

        if outer == "Vec":
            return vector
        elif outer == "Mat":
            return matrix
    
    raise newException(ValueError, "Unrecognized type '" & typeNode.treeRepr() & "'!")

# usage

macro formatVertexArray*(program: ShaderProgram, typeBody: untyped): untyped =
    ## Processes the given type declaration AST into 
    ## vertex attribute pointers according to the fields.
    
    result = newStmtList()

    # typeBody
    # using code
    #[
        type
            Vertex = object
                pos: Vec[2, float32]
    ]#
    # produces
    #[
        StmtList
            TypeSection
                TypeDef
                    Ident "Vertex"
                    Empty
                    ObjectTy
                        Empty
                        Empty
                        RecList
                            IdentDefs
                                Ident "pos"
                                BracketExpr
                                    Ident "Vec"
                                    IntLit 2
                                    Ident "float32"
                                Empty
    ]#

    let section = typeBody[0]
    let definition = section[0]

    let theType = definition[2]
    let fields = theType[2]

    # generate stride

    var stride: int32

    for field in fields:
        let fieldType = field[1]
        let attributeType = getAttributeType(fieldType)

        var dataKind: GlEnum

        case attributeType
        of scalar:
            dataKind = dataKindOf($fieldType)
        of vector:
            dataKind = dataKindOf($fieldType[2])
        of matrix:
            dataKind = dataKindOf($fieldType[3])

        stride += dataSizeOf(dataKind)

    # format attributes

    var offset: int32

    for field in fields:
        # potential issue: this only supports one name
        let name = $field[0]
        let fieldType = field[1]
        let attributeType = getAttributeType(fieldType)

        var dataKind: GlEnum

        case attributeType
        of scalar:
            dataKind = dataKindOf($fieldType)

            result.add(formatScalar(program, name, offset, dataKind, stride))
        of vector:
            let height = fieldType[1].intVal().int32()
            dataKind = dataKindOf($fieldType[2])

            result.add(formatVector(program, name, height, offset, dataKind, stride))
        of matrix:
            let width = fieldType[1].intVal().int32()
            let height = fieldType[2].intVal().int32()
            dataKind = dataKindOf($fieldType[3])

            result.add(formatMatrix(program, name, width, height, offset, dataKind, stride))

        offset += dataSizeOf(dataKind)

    echo result.repr()

let program = newProgram()

formatVertexArray(program):
    type
        Vertex = object
            pos: Vec[2, float32]
            color: Vec[4, uint8]
            model: Mat[4, 4, float32]