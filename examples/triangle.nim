import ../src/seed/graphics/gl, windy, shady, opengl, sequtils

#[
    TODO:
    (completed) 1. implement element buffer handling
    (completed) 2. remove height as a property of inputs/buffers; setting it at initialization was naive
    (completed) 3. implement uniforms
    4. implement textures
    - subpoint: I still need to implement atlases
]#

let window = newWindow("Triangle example", ivec2(1280, 800), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

proc vertex(xOffset: shady.Uniform[float32], aPos: Vec3, aColor: Vec3, gl_Position: var Vec4, vertexColor: var Vec3) =
    gl_Position = vec4(aPos.x + xOffset, aPos.y, aPos.z, 1f)
    vertexColor = aColor

proc fragment(fragColor: var Vec4, vertexColor: Vec3) =
    fragColor = vec4(vertexColor.x, vertexColor.y, vertexColor.z, 1f)

var
    vertexText = toGLSL(vertex, "330", "")
    fragmentText = toGLSL(fragment, "330", "")

let vertexShader = newShader(vertexShader, vertexText)
let fragmentShader = newShader(fragmentShader, fragmentText)

let program = newProgram()
program.shaders = (vertexShader, fragmentShader)
program.link()

let
    xOffset = program.newUniform[:float32]("xOffset", floatUniform)

let vertices = @[
    -0.5f, -0.5f, 0f,
    0.5f,  -0.5f, 0f,
    -0.5f, 0.5f,  0f,
    0.5f,  0.5f,  0f
]

let colors = @[
    1f, 0f, 0f,
    0f, 1f, 0f,
    0f, 1f, 0f,
    0f, 0f, 1f
]

let indices = @[
    0, 1, 2,
    1, 2, 3
].mapIt(it.uint32)

let inputs = newInputs(("aPos", 3), ("aColor", 3))
let vertexBuffer = newVertexBuffer(floatData, inputs)

let elementBuffer = newElementBuffer()

let vertexArray = newVertexArray(@[vertexBuffer])

with(vertexArray, true):
    with(vertexBuffer, false):
        vertexBuffer.send(staticDraw, @[vertices, colors])

    with(elementBuffer, false):
        elementBuffer.send(staticDraw, indices)

    vertexArray.configurePointers(program)

proc display() =
    glClearColor(0f, 0f, 0f, 1f)
    glClear(GL_COLOR_BUFFER_BIT)

    use(program)
    use(vertexArray)

    xOffset.update(0.5f)

    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, cast[pointer](0))

    window.swapBuffers()

while not window.closeRequested:
    display()
    pollEvents()