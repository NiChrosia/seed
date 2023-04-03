import ../../api/gl/[buffers, ssbos], ../../api/rendering/atlases
import opengl, vmath

type
    PolyBatch* = object
        vao: GLuint
        vertices: Buffer

        modelBuffer: ptr Ssbo
        atlas: ptr Atlas

        triangles: GLint

    Vertex = object
        position:   Vec3
        texCoords:  Vec2
        modelIndex: GLint
        tint: Vec4

proc init*(_: typedesc[PolyBatch], theAtlas: ptr Atlas, theModelBuffer: ptr Ssbo): PolyBatch =
    # buffers
    result.vertices = Buffer.init(GL_DYNAMIC_DRAW)

    result.modelBuffer = theModelBuffer
    result.atlas = theAtlas

    # vao
    glCreateVertexArrays(1, addr result.vao)

    block vertex:
        glVertexArrayVertexBuffer(result.vao, 0, result.vertices.handle, 0, GLsizei(sizeof(Vertex)))

        for i in 0 .. 3:
            glEnableVertexArrayAttrib(result.vao, GLuint(i))

        glVertexArrayAttribFormat(result.vao, 0, 3, cGL_FLOAT, false, GLuint(Vertex.offsetOf(position)))
        glVertexArrayAttribFormat(result.vao, 1, 2, cGL_FLOAT, false, GLuint(Vertex.offsetOf(texCoords)))
        glVertexArrayAttribIFormat(result.vao, 2, 1, cGL_INT, GLuint(Vertex.offsetOf(modelIndex)))
        glVertexArrayAttribFormat(result.vao, 3, 4, cGL_FLOAT, false, GLuint(Vertex.offsetOf(tint)))

        for i in 0 .. 3:
            glVertexArrayAttribBinding(result.vao, GLuint(i), 0)

proc draw*(batch: PolyBatch) =
    ## program with matching bindings should be bound

    glBindVertexArray(batch.vao)
    glDrawArrays(GL_TRIANGLES, 0, 3 * batch.triangles)

# shape drawing function helpers
template indexModel(batch: var PolyBatch, model: Mat4): GLint =
    let index = GLint(batch.modelBuffer[].buffer.used div sizeof(Mat4))
    batch.modelBuffer[].buffer.add(sizeof(Mat4), unsafeAddr model)

    index

template transformTcs(batch: PolyBatch, texture: string, local: Vec2): Vec2 =
    batch.atlas[].coords(texture, local)

proc transformVertices(batch: var PolyBatch, poss: openArray[Vec3], texture: string, tcs: openArray[Vec2], tint: Vec4, model: Mat4): seq[Vertex] =
    for i in 0 ..< poss.len:
        let tc = batch.transformTcs(texture, tcs[i])
        let mi = batch.indexModel(model)

        result.add(Vertex(position: poss[i], texCoords: tc, modelIndex: mi, tint: tint))

# user-facing API
# - quads
let fromOriginClockwiseQuadTexCoords* = [
    vec2(0f, 0f),
    vec2(0f, 1f),
    vec2(1f, 1f),
    vec2(0f, 1f)
]

proc quad*(batch: var PolyBatch, positions: openArray[Vec3], texture: string, tint: Vec4, model: Mat4) =
    ## positions are expected to be in the positioning
    ## 1 2
    ## 0 3
    ## due to this expectation, the texture coordinates are implicit

    var vertices = batch.transformVertices(positions, texture, fromOriginClockwiseQuadTexCoords, tint, model)
    var mesh = newSeq[Vertex]()

    # counterclockwise
    for i in [3, 2, 1, 1, 0, 3]:
        mesh.add(vertices[i])

    batch.vertices.add(sizeof(Vertex) * mesh.len, unsafeAddr mesh[0])
    batch.triangles += 2

proc rect*(batch: var PolyBatch, texture: string, tint: Vec4, a, b: Vec2, model: Mat4) =
    let positions = [
        vec3(a.x, a.y, 0f),
        vec3(a.x, b.y, 0f),
        vec3(b.x, b.y, 0f),
        vec3(b.x, a.y, 0f),
    ]

    batch.quad(positions, texture, tint, model)

proc square*(batch: var PolyBatch, texture: string, tint: Vec4, point: Vec2, model: Mat4) =
    let positions = [
        vec3(point * vec2(-1f, -1f), 0f),
        vec3(point * vec2(-1f, +1f), 0f),
        vec3(point * vec2(+1f, +1f), 0f),
        vec3(point * vec2(+1f, -1f), 0f),
    ]

    batch.quad(positions, texture, tint, model)
