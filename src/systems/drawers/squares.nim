import ../../api/gl/[buffers, ssbos], ../../api/rendering/atlases
import opengl, vmath

type
    QuadBatch* = object
        vao: GLuint
        vertices: Buffer

        modelBuffer: ptr Ssbo
        atlas: ptr Atlas

        quadCount: GLint

    Vertex = object
        position:   Vec3
        texCoords:  Vec2
        modelIndex: int

proc init*(_: typedesc[QuadBatch], theAtlas: ptr Atlas, theModelBuffer: ptr Ssbo): QuadBatch =
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
        glVertexArrayAttribFormat(result.vao, 2, 1, cGL_INT, false, GLuint(Vertex.offsetOf(modelIndex)))

        glVertexArrayAttribBinding(result.vao, 0, 0)
        glVertexArrayAttribBinding(result.vao, 1, 0)
        glVertexArrayAttribBinding(result.vao, 2, 0)

proc draw*(batch: QuadBatch) =
    ## program with matching bindings should be bound

    glBindVertexArray(batch.vao)
    glDrawArrays(GL_TRIANGLES, 0, GLsizei(6 * batch.quadCount))

# user-facing API
proc quad*(batch: var QuadBatch, positions: array[4, Vec3], quadTexCoords: array[4, Vec2], texture: string, model: Mat4) =
    let index = GLint(batch.modelBuffer[].buffer.used div sizeof(Mat4))
    batch.modelBuffer[].buffer.add(sizeof(Mat4), unsafeAddr model)

    var vertices: array[4, Vertex]

    for i in 0 .. 3:
        let texCoords = batch.atlas[].coords(texture, quadTexCoords[i])

        vertices[i] = Vertex(position: positions[i], texCoords: texCoords, modelIndex: index)

    for i in [2, 1, 0, 1, 2, 3]:
        batch.vertices.add(sizeof(Vertex), unsafeAddr vertices[i])

    batch.quadCount += 1

proc square*(batch: var QuadBatch, texture: string, point: Vec2, model: Mat4) =
    var positions: array[4, Vec3]
    var quadTexCoords: array[4, Vec2]

    for i in 0 .. 3:
        let xSign = float((i div 2) * 2 - 1)
        let ySign = float((i mod 2) * 2 - 1)

        let newPoint = vec3(point.x * xSign, point.y * ySign, -1f)
        let texCoords = (vec2(xSign, ySign) + 1f) / 2f

        positions[i] = newPoint
        quadTexCoords[i] = texCoords

    batch.quad(positions, quadTexCoords, texture, model)
