import ../core/vertex_arrays, ../core/shaders
import opengl

import std/[macros, genasts, sugar]

type
    Vec*[H: static[int]; T] = array[H, T]
    Mat*[W, H: static[int]; T] = array[W * H, T]

type
    Id = object
        name: string

        case instanced: bool
        of true:
            divisor: uint32
        of false:
            discard

    FormatFunction = (program: NimNode, id: Id, offset: int32, stride: int32) -> NimNode

    Format = object
        function: FormatFunction
        size: int32

    Attribute = object
        id: Id
        offset: int32

        format: Format

# nodes

proc asInt[I](node: NimNode): I =
    let asBiggestInt = node.intVal()

    return I(asBiggestInt)

# pragmas

proc getPragmaName(pragma: NimNode): string =
    case pragma.kind
    of nnkIdent:
        return $pragma
    of nnkCall:
        return $pragma[0]
    else:
        return ""

proc getDivisor(pragma: NimNode): uint32 =
    case pragma.kind
    of nnkIdent:
        return 1
    of nnkCall:
        return pragma[1].asInt[:uint32]()
    else:
        return 0

# ids

proc processIdentId(identId: NimNode): Id =
    let name = $identId

    return Id(name: name, instanced: false)

proc processPragmaId(pragmaId: NimNode): Id =
    let name = $pragmaId[0]
    let pragmaNode = pragmaId[1]

    for pragma in pragmaNode:
        let pragmaName = pragma.getPragmaName()

        if pragmaName != "instanced":
            continue

        let divisor = pragma.getDivisor()

        return Id(name: name, instanced: true, divisor: divisor)

proc processId(name: NimNode): Id =
    case name.kind
    of nnkIdent:
        return processIdentId(name)
    of nnkPragmaExpr:
        return processPragmaId(name)
    else:
        error("Unexpected id type!", name)

# formats

proc processScalar(typeNode: NimNode): Format =
    let name = $typeNode
    let kind = dataKindOf(name)

    let altKind = uint32(kind)

    result.size = dataSizeOf(kind)
    result.function = proc(program: NimNode, id: Id, offset: int32, stride: int32): NimNode =
        return genAst(program, id, offset, altKind, stride) do:
            let index = program.newAttributeIndex(id.name)

            setScalar(index, GlEnum(altKind), offset, stride, false)

            if id.instanced:
                setDivisor(index, id.divisor)

proc processVector(typeNode: NimNode): Format =
    let height = typeNode[1].asInt[:int32]()

    let name = $typeNode[2]
    let kind = dataKindOf(name)

    let altKind = uint32(kind)

    result.size = height * dataSizeOf(kind)
    result.function = proc(program: NimNode, id: Id, offset: int32, stride: int32): NimNode =
        return genAst(program, id, offset, height, altKind, stride) do:
            let index = program.newAttributeIndex(id.name)

            setVector(index, GlEnum(altKind), offset, height, stride)

            if id.instanced:
                setDivisor(index, id.divisor)

proc processMatrix(typeNode: NimNode): Format =
    let width = typeNode[1].asInt[:int32]()
    let height = typeNode[2].asInt[:int32]()

    let name = $typeNode[3]
    let kind = dataKindOf(name)

    let altKind = uint32(kind)

    result.size = width * height * dataSizeOf(kind)
    result.function = proc(program: NimNode, id: Id, offset: int32, stride: int32): NimNode =
        return genAst(program, id, offset, width, height, altKind, stride) do:
            let index = program.newAttributeIndex(id.name)

            setMatrix(index, GlEnum(altKind), offset, width,height, stride)

            if id.instanced:
                setDivisor(index, id.divisor)

proc processFormat(typeNode: NimNode): Format =
    case typeNode.kind
    of nnkIdent:
        return processScalar(typeNode)
    of nnkBracketExpr:
        let name = $typeNode[0]

        case name
        of "Vec":
            return processVector(typeNode)
        of "Mat":
            return processMatrix(typeNode)
        else:
            error("Unrecognized bracket type!", typeNode)
    else:
        error("Unrecognized node type!", typeNode)

# usage

#[
relevant trees:

type
    Vertex = object
        pos: Vec[2, float32]

    Props = object
        color: Vec[4, float32]
        model: Mat[4, 4, float32]

    Index = uint8
->
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
        TypeDef
            Ident "Props"
            Empty
            ObjectTy
                Empty
                Empty
                RecList
                    IdentDefs
                        Ident "color"
                        BracketExpr
                            Ident "Vec"
                            IntLit 4
                            Ident "float32"
                        Empty
                    IdentDefs
                        Ident "model"
                        BracketExpr
                            Ident "Mat"
                            IntLit 4
                            IntLit 4
                            Ident "float32"
                        Empty
        TypeDef
            Ident "Index"
            Empty
            Ident "uint8"
]#

#[
let x {.a, b(1).} = 1
->
StmtList
    LetSection
        IdentDefs
            PragmaExpr
                Ident "x"
                Pragma
                    Ident "a"
                    Call
                        Ident "b"
                        IntLit 1
            Empty
            IntLit 1
]#

macro formatAttributesWith*(program: ShaderProgram, typeBody: untyped): untyped =
    result = newStmtList()

    let section = typeBody[0]

    for definition in section:
        let definitionId = processId(definition[0])

        let declaration = definition[2]
        let fields = declaration[2]

        var attributes: seq[Attribute]
        var offset: int32 = 0

        for field in fields:
            var id = processId(field[0])
            let format = processFormat(field[1])
            
            # if the type id is instanced and this field isn't
            # (meaning you can override the type level instanced)
            if definitionId.instanced and not id.instanced:
                # set the instanced values to the type's
                id.instanced = definitionId.instanced
                id.divisor = definitionId.divisor

            let attribute = Attribute(id: id, offset: offset, format: format)
            attributes.add(attribute)

            offset += format.size

        let stride = offset

        for attribute in attributes:
            let id = attribute.id
            let offset = attribute.offset
            let function = attribute.format.function

            let formatted = function(program, id, offset, stride)
            result.add(formatted)