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

proc init*(_: typedesc[PolyBatch], theAtlas: ptr Atlas, theModelBuffer: ptr Ssbo): PolyBatch =
    # buffers
    result.vertices = Buffer.init(GL_DYNAMIC_DRAW)

    result.modelBuffer = theModelBuffer
    result.atlas = theAtlas

    # vao
    glCreateVertexArrays(1, addr result.vao)

    block vertex:
        glVertexArrayVertexBuffer(result.vao, 0, result.vertices.handle, 0, GLsizei(sizeof(Vertex)))

        glEnableVertexArrayAttrib(result.vao, 0)
        glEnableVertexArrayAttrib(result.vao, 1)
        glEnableVertexArrayAttrib(result.vao, 2)

        glVertexArrayAttribFormat(result.vao, 0, 3, cGL_FLOAT, false, GLuint(Vertex.offsetOf(position)))
        glVertexArrayAttribFormat(result.vao, 1, 2, cGL_FLOAT, false, GLuint(Vertex.offsetOf(texCoords)))
        glVertexArrayAttribIFormat(result.vao, 2, 1, cGL_INT, GLuint(Vertex.offsetOf(modelIndex)))

        glVertexArrayAttribBinding(result.vao, 0, 0)
        glVertexArrayAttribBinding(result.vao, 1, 0)
        glVertexArrayAttribBinding(result.vao, 2, 0)

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

proc transformVertices(batch: var PolyBatch, poss: openArray[Vec3], texture: string, tcs: openArray[Vec2], model: Mat4): seq[Vertex] =
    for i in 0 ..< poss.len:
        let tc = batch.transformTcs(texture, tcs[i])
        let mi = batch.indexModel(model)

        result.add(Vertex(position: poss[i], texCoords: tc, modelIndex: mi))

# user-facing API
proc quad*(batch: var PolyBatch, positions: array[4, Vec3], texture: string, quadTexCoords: array[4, Vec2], model: Mat4) =
    var vertices = batch.transformVertices(positions, texture, quadTexCoords, model)

    # 0, 1, 2; 2, 3; 0
    batch.vertices.add(sizeof(Vertex) * 3, unsafeAddr vertices[0])
    batch.vertices.add(sizeof(Vertex) * 2, unsafeAddr vertices[2])
    batch.vertices.add(sizeof(Vertex) * 1, unsafeAddr vertices[0])

    batch.triangles += 2

proc square*(batch: var PolyBatch, texture: string, point: Vec2, model: Mat4) =
    var positions: array[4, Vec3]
    var quadTexCoords: array[4, Vec2]

    for i in 0 .. 3:
        let xSign = float((i div 2) * 2 - 1)
        let ySign = float((i mod 2) * 2 - 1)

        let newPoint = vec3(point.x * xSign, point.y * ySign, -1f)
        let texCoords = (vec2(xSign, ySign) + 1f) / 2f

        positions[i] = newPoint
        quadTexCoords[i] = texCoords

    batch.quad(positions, texture, quadTexCoords, model)
