import ../src/seed/graphics/[gl, images], windy, shady, opengl, sequtils

#[
    (items do not necessarily need to be completed in order)

    TODO:
    (completed) 1. implement element buffer handling
    (completed) 2. remove height as a property of inputs/buffers; setting it at initialization was naive
    (completed) 3. implement uniforms
    (completed) 4. implement textures
    (no[t yet]) 4.1: implement texture atlases
    5. implement medium-level shape rendering (ie. handled drawing, procs like `data.vertex(x, y, z); renderer.draw(data)`)
    6. implement medium-level texture rendering
    7. implement high-level rendering (ie. being able to draw things without any setup aside from `seed.initialize()`)
]#

let window = newWindow("Triangle example", ivec2(800, 800), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

proc vertex(xOffset: Uniform[float32], aPos: Vec3, aTexCoord: Vec2, gl_Position: var Vec4, texCoord: var Vec2) =
    gl_Position = vec4(aPos.x + xOffset, aPos.y, aPos.z, 1f)
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

let vertexShader = newShader(vertexShader, vertexText)
let fragmentShader = newShader(fragmentShader, fragmentText)

let program = newProgram()
program.shaders = (vertexShader, fragmentShader)
program.link()

let
    xOffset = program.newUniform[:float32]("xOffset", floatUniform)

var
    image = openImage("res/sprites/box.qoi")
    texture = program.newTexture2("theTexture", image)

with(texture, true):
    texture.wrapX = kinds.repeat
    texture.wrapY = kinds.repeat

    texture.minFilter = linear
    texture.magFilter = linear

    texture.generate()

let vertices = @[
    -0.5f, -0.5f, 0f,
    0.5f,  -0.5f, 0f,
    -0.5f, 0.5f,  0f,
    0.5f,  0.5f,  0f
]

let texCoords = @[
    0f, 0f, 0f,
    1f, 0f, 0f,
    0f, 1f, 0f,
    1f, 1f, 0f
]

let indices = @[
    0, 1, 2,
    1, 2, 3
].mapIt(it.uint32)

let inputs = newInputs(("aPos", 3), ("aTexCoord", 3))
let vertexBuffer = newVertexBuffer(floatData, inputs)

let elementBuffer = newElementBuffer()

let vertexArray = newVertexArray(@[vertexBuffer])

with(vertexArray, true):
    with(vertexBuffer, false):
        vertexBuffer.send(staticDraw, @[vertices, texCoords])

    with(elementBuffer, false):
        elementBuffer.send(staticDraw, indices)

    vertexArray.configurePointers(program)

with(program, true):
    texture.uniform.update(0)

proc display() =
    glClearColor(0f, 0f, 0f, 1f)
    glClear(GL_COLOR_BUFFER_BIT)

    texture.slot = activeTexture0
    use(texture)

    use(program)
    use(vertexArray)

    xOffset.update(0.5f)

    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, cast[pointer](0))

    window.swapBuffers()

while not window.closeRequested:
    display()
    pollEvents()