import ../src/seed/video/backends/gl, ../src/seed/video/[images, cameras], windy, shady, opengl, std/[sequtils, math, random, times], vmath

let window = newWindow("Deca-hexahedron example", ivec2(800, 600), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

proc vertex(model: Uniform[Mat4], view: Uniform[Mat4], projection: Uniform[Mat4], aPos: Vec3, aTexCoord: Vec2, gl_Position: var Vec4, texCoord: var Vec2) =
    gl_Position = projection * view * model * vec4(aPos.x, aPos.y, aPos.z, 1f)
    texCoord = aTexCoord

var
    vertexText = toGLSL(vertex, "330", "")
    fragmentText = """#version 330
uniform sampler2D theTexture;

in vec2 texCoord;

out vec4 FragColor;

void main() {
    FragColor = texture(theTexture, texCoord);
}
"""

let vertexShader = newShader(GL_VERTEX_SHADER, vertexText)
let fragmentShader = newShader(GL_FRAGMENT_SHADER, fragmentText)

let program = newProgram()
program.shaders = (vertexShader, fragmentShader)
program.link()

let
    model = program.newUniform[:Mat4]("model", updateMatrix)
    view = program.newUniform[:Mat4]("view", updateMatrix)
    projection = program.newUniform[:Mat4]("projection", updateMatrix)

    textureId = program.newTextureUniform("theTexture")

var
    image = open("res/sprites/box.qoi").read(qoi)
    texture = newTexture2(image)

with(texture, true):
    texture.wrapX = GL_REPEAT
    texture.wrapY = GL_REPEAT

    texture.minFilter = GL_LINEAR
    texture.magFilter = GL_LINEAR

    texture.generate()

let vertices = @[
    -1f, -1f, -1f, # left bottom back
    -1f, 1f, -1f, # left top back
    1f, -1f, -1f, # right bottom back
    1f, 1f, -1f, # right top back

    -1f, -1f, 1f, # left bottom front
    -1f, 1f, 1f, # left top front
    1f, -1f, 1f, # right bottom front
    1f, 1f, 1f, # right top front
]

let texCoords = @[
    0f, 0f, 0f, # bottom-left
    1f, 0f, 0f, # bottom-right
    0f, 1f, 0f, # top-left
    1f, 1f, 0f, # top-right

    1f, 0f, 0f, # bottom-right
    0f, 0f, 0f, # bottom-left
    1f, 1f, 0f, # top-right
    0f, 1f, 0f, # top-left
]

let indices = @[
    0, 1, 2, # back
    1, 2, 3,

    0, 4, 2, # left
    4, 2, 6,

    5, 1, 7, # right
    1, 7, 3,

    4, 5, 6, # front
    5, 6, 7,

    4, 5, 0, # bottom
    5, 0, 1,

    6, 7, 3, # top
    7, 3, 4
].mapIt(it.uint32)

let
    inputs = newInputs(("aPos", 3), ("aTexCoord", 3))
    vertexBuffer = newVertexBuffer(float32, cGL_FLOAT, inputs)

    elementBuffer = newElementBuffer()

    vertexArray = newVertexArray(@[vertexBuffer])

with(vertexArray, true):
    with(vertexBuffer, false):
        vertexBuffer.send(GL_STATIC_DRAW, @[vertices, texCoords])

    with(elementBuffer, false):
        elementBuffer.send(GL_STATIC_DRAW, indices)

    vertexArray.configurePointers(program)

with(program, true):
    textureId.update(0)

    model.update(mat4())
    view.update(mat4())
    projection.update(perspective(45f, window.size.x / window.size.y, 0.1f, 100f))

glEnable(GL_DEPTH_TEST)

var
    movement = newMovement3D(0.5f, wasdSpaceShift)
    rotation = newMouseRotation(1f)

    camera = newCamera3D(vec3(0f, 0f, 15f), movement, vec3(0f, 0f, -1f), vec3(0f, 1f, 0f), rotation)

var
    deltaTime = 0f
    lastFrame = 0f

proc handleInput() =
    camera.move(window.buttonDown)

window.onFrame = proc() =
    glClearColor(0f, 0f, 0f, 1f)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    let currentFrame = epochTime()
    deltaTime = currentFrame - lastFrame
    lastFrame = currentFrame

    use(texture, 0)

    use(program)
    use(vertexArray)

    view.update(camera.matrix)

    randomize(0)

    for i in 0 .. 9:
        let x = rotateX(rand(i * 40).float32.toRadians)
        let y = rotateY(rand(i * 40).float32.toRadians)
        let translate = translate(vec3(rand(1f..5f), rand(1f..5f), rand(1f..5f)))

        model.update(x * y * translate)

        glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_INT, cast[pointer](0))

    window.swapBuffers()

window.onResize = proc() =
    glViewport(0, 0, window.size.x, window.size.y)

window.onMouseMove = proc() =
    camera.rotate(window.mousePos)

while not window.closeRequested:
    handleInput()
    pollEvents()