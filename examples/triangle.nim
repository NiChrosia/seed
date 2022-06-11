import ../src/seed/graphics/gl, windy, shady, opengl, sequtils

#[
    TODO:
    1. implement element buffer handling
    2. implement textures
    3. implement uniforms
]#

let window = newWindow("Triangle example", ivec2(1280, 800), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

proc vertex(gl_Position: var Vec4, aPos: Vec3, aColor: Vec3, vertexColor: var Vec3) =
    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1f)
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

let vertices = @[
    -0.5f, -0.5f, 0f,
    0.5f,  -0.5f, 0f,
    0f,    0.5f,  0f
]

let colors = @[
    1f, 0f, 0f,
    0f, 1f, 0f,
    0f, 0f, 1f
]

let indices = @[
    0, 1, 2
].mapIt(it.uint32)

let inputs = newInputs(3, ("aPos", 3), ("aColor", 3))
let vertexBuffer = newVertexBuffer(floatData, inputs)

let elementBuffer = newElementBuffer()

let vertexArray = newVertexArray(@[vertexBuffer])

glContext.vertexArray = vertexArray

glContext[arrayBuffer] = vertexBuffer
vertexBuffer.send(staticDraw, @[vertices, colors])

glContext[elementArrayBuffer] = elementBuffer
elementBuffer.send(staticDraw, indices)

vertexArray.configurePointers(program)

glContext.vertexArray = nil

proc display() =
    glClearColor(0f, 0f, 0f, 1f)
    glClear(GL_COLOR_BUFFER_BIT)

    glContext.program = program
    glContext.vertexArray = vertexArray

    glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_INT, cast[pointer](0))
    #glDrawArrays(GL_TRIANGLES, 0, 3)

    window.swapBuffers()

while not window.closeRequested:
    display()
    pollEvents()