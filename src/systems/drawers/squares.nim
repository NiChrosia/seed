import ../../api/gl/[buffers, ssbos], ../../api/rendering/atlases
import opengl, vmath

type
    Vertex = object
        pos: Vec3
        texCoords: Vec2
        modelIndex: GLint

var
    vao: GLuint
    vbo, pbo: GLuint

var
    vertices: Buffer
    properties: Buffer
    count = 0

    modelBuffer: ptr Ssbo
    atlas: ptr Atlas

proc setup*(theAtlas: ptr Atlas, theModelBuffer: ptr Ssbo) =
    # buffers
    vertices = Buffer.init(GL_DYNAMIC_DRAW)
    properties = Buffer.init(GL_DYNAMIC_DRAW)

    vbo = vertices.handle
    pbo = properties.handle

    modelBuffer = theModelBuffer
    atlas = theAtlas

    # vao
    glCreateVertexArrays(1, addr vao)

    block vertex:
        glVertexArrayVertexBuffer(vao, 0, vbo, 0, GLsizei(sizeof(Vertex)))

        glEnableVertexArrayAttrib(vao, 0)
        glEnableVertexArrayAttrib(vao, 1)
        glEnableVertexArrayAttrib(vao, 2)

        glVertexArrayAttribFormat(vao, 0, 3, cGL_FLOAT, false, GLuint(Vertex.offsetOf(pos)))
        glVertexArrayAttribFormat(vao, 1, 2, cGL_FLOAT, false, GLuint(Vertex.offsetOf(texCoords)))
        glVertexArrayAttribFormat(vao, 2, 1, cGL_INT, false, GLuint(Vertex.offsetOf(modelIndex)))

        glVertexArrayAttribBinding(vao, 0, 0)
        glVertexArrayAttribBinding(vao, 1, 0)
        glVertexArrayAttribBinding(vao, 2, 0)

    # block property:
    #     glVertexArrayVertexBuffer(vao, 1, pbo, 0, GLsizei(sizeof(Property)))

    #     for row in 0 .. 3:
    #         let index = GLuint(2 + row)
    #         let offset = GLuint(Property.offsetOf(model) + sizeof(Vec4) * row)

    #         glEnableVertexArrayAttrib(vao, index)
    #         glVertexArrayAttribFormat(vao, index, 4, cGL_FLOAT, false, offset)
    #         glVertexArrayAttribBinding(vao, index, 1)

    #     glVertexArrayBindingDivisor(vao, 1, 1)

proc draw*(program: GLuint) =
    # draw
    glBindVertexArray(vao)
    glUseProgram(program)

    glDisable(GL_CULL_FACE)

    glDrawArrays(GL_TRIANGLES, 0, GLsizei(6 * count))

# user-facing API
proc square*(texture: string, point: Vec2, model: Mat4 = mat4()) =
    let index = GLint(modelBuffer[].buffer.used div sizeof(Mat4))
    modelBuffer[].buffer.add(sizeof(Mat4), unsafeAddr model)

    var indices = newSeq[Vertex]()

    for xSign in [-1f, 1f]:
        for ySign in [-1f, 1f]:
            let newPoint = vec3(point.x * xSign, point.y * ySign, -1f)
            let normTexCoords = (vec2(xSign, ySign) + 1f) / 2f

            let texCoords = atlas[].coords(texture, normTexCoords)

            indices.add(Vertex(modelIndex: index, pos: newPoint, texCoords: texCoords))

    for i in countdown(2, 0):
        vertices.add(sizeof(Vertex), addr indices[i])

    for i in 1 .. 3:
        vertices.add(sizeof(Vertex), addr indices[i])

    count += 1
