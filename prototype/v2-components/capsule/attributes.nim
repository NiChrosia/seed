import ../core/vertex_arrays, ../core/shaders

import opengl

import std/[macros]

type
    Vec*[H: static[int]; T] = array[H, T]
    Mat*[W, H: static[int]; T] = array[W * H, T]

proc formatScalar*(
    program: NimNode, 
    name: string, offset: int32, attributeType: GlEnum,
    stride: int32
): NimNode =
    discard

proc formatVector*(
    program: NimNode, 
    name: string, height: int32, offset: int32, attributeType: GlEnum, 
    stride: int32, 
): NimNode =
    discard

proc formatMatrix*(
    program: NimNode, 
    name: string, width, height: int32, offset: int32, attributeType: GlEnum, 
    stride: int32, 
): NimNode =
    discard

macro formatVertexArray*(program: uint32, typeBody: untyped): untyped =
    ## Processes the given type declaration AST into 
    ## vertex attribute pointers according to the fields.
    
    result = newStmtList()

    # typeBody
    # using code
    #[
        type
            Vertex = object
                pos: array[2, float32]
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
                                    Ident "array"
                                    IntLit 2
                                    Ident "float32"
                                Empty
    ]#

    let typeSize: int32 = 0

    let section = typeBody[0]
    let definition = section[0]

    let theType = definition[2]
    let fields = theType[2]

    var offset: int32 = 0

    for field in fields:
        # potential issue: this only supports one name
        let name = $field[0]
        let fieldType = field[1]

        if fieldType.kind == nnkIdent:
            let attributeType = dataKindOf($fieldType)

            result.add(formatScalar(program, name, offset, attributeType, typeSize))
        elif fieldType.kind == nnkBracketExpr:
            let typeName = $fieldType[0]

            if typeName == "Vec":
                let height = int32(fieldType[1].intVal())

                let attributeType = dataKindOf($fieldType[2])

                result.add(formatVector(program, name, height, offset, attributeType, typeSize))
            elif typeName == "Mat":
                let width = int32(fieldType[1].intVal())
                let height = int32(fieldType[2].intVal())

                let attributeType = dataKindOf($fieldType[3])

                result.add(formatMatrix(program, name, width, height, offset, attributeType, typeSize))

formatVertexArray(0):
    type
        Vertex = object
            pos: array[2, float32]