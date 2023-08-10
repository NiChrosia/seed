import ../../api/gl/[buffers, ssbos, attrs], ../../api/rendering/atlases
import opengl, vmath

type
    PolyBatch* = object
        vao: GLuint
        vertices: Buffer

        modelBuffer: ptr Ssbo
        atlas: ptr Atlas

        queue: seq[Vertex]
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

    attributes(result.vao)
        .buffer(sequential(result.vertices.handle)
            .vec(float, 3)
            .vec(float, 2)
            .sca(int)
            .vec(float, 4)
            .build())
        .build()

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

proc flush*(batch: var PolyBatch) =
    if batch.queue.len <= 0:
        return

    batch.vertices.add(sizeof(Vertex) * batch.queue.len, unsafeAddr batch.queue[0])
    batch.queue.setLen(0)

# user-facing API
proc rect*(batch: var PolyBatch, texture: string, tint: Vec4, a, b: Vec2, model: Mat4) =
    let positions = [
        vec3(a.x, a.y, 0f),
        vec3(a.x, b.y, 0f),
        vec3(b.x, b.y, 0f),
        vec3(b.x, a.y, 0f),
    ]

    const tcs = [
        vec2(1f, -1f),
        vec2(1f, 1f),
        vec2(-1f, 1f),
        vec2(-1f, -1f),
    ]

    let vertices = batch.transformVertices(positions, texture, tcs, tint, model)

    for i in [0, 1, 2, 2, 3, 0]:
        batch.queue.add(vertices[i])

    batch.triangles += 2

proc poly*(batch: var PolyBatch, numVertices: int, tint: Vec4, radius: float, model: Mat4) =
    # generate positions
    var positions: seq[Vec3]
    let fraction = TAU / float(numVertices)

    for i in 0 ..< numVertices:
        let radians = fraction * float(i)
        positions.add(vec3(radius * cos(radians), radius * sin(radians), 0f))

    # generate vertices
    let tc = batch.transformTcs("white", vec2(0.5f))
    let mi = batch.indexModel(model)

    var vertices: seq[Vertex]

    for i in 0 ..< positions.len:
        vertices.add(Vertex(position: positions[i], texCoords: tc, modelIndex: mi, tint: tint))

    vertices.add(Vertex(position: vec3(), texCoords: tc, modelIndex: mi, tint: tint))

    # apply fan triangulation to vertices
    for i in 0 ..< (vertices.len - 1):
        batch.queue.add(vertices[vertices.high])
        batch.queue.add(vertices[i])
        batch.queue.add(vertices[(i + 1) mod (vertices.len - 1)])

    batch.triangles += GLint(numVertices)
