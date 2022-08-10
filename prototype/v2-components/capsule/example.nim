import ../core/buffers, ../core/vertex_arrays, ../core/shaders
import attributes
import vmath, windy
import opengl

# window

let window = newWindow("Example", ivec2(800, 600), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

# data

type
    Vertex = Vec2

    Properties = object
        color: Vec4
        model: Mat4

    Index = uint8

var vertices = [
    vec2(-1f, -1f), vec2(-1f, 1f), vec2(1f, -1f), vec2(1f, 1f)
]

var properties = [
    Properties(model: translate(vec3(-1f, -1f, 0f)).transpose())
]

var indices = [
    Index(0), 1, 2,
    1, 2, 3
]

# shaders

let vertexSource = """#version 330

in vec2 pos;
in mat4 model;

out vec4 vColor;

void main() {
    mat4 fakeModel = mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        -1.0, -1.0, 0.0, 1.0
    );

    gl_Position = model * vec4(vec3(pos, 0.0), 1.0) + model[0] - model[0];
    vColor = vec4(pos.x, 0.0, pos.y, 1.0);
}"""

let fragmentSource = """#version 330

in vec4 vColor;

out vec4 fragColor;

void main() {
    fragColor = vColor;
}"""

let vertexShader = newShader(GlVertexShader)
vertexShader.compile(vertexSource)

let fragmentShader = newShader(GlFragmentShader)
fragmentShader.compile(fragmentSource)

let program = newProgram()
program.connectTo(vertexShader, fragmentShader)
program.link()

# buffers

let vertexArray = newVertexArray()

let vertexBuffer = newBuffer()
let propertyBuffer = newBuffer()
let indexBuffer = newBuffer()

let usage = GlDynamicDraw

# configuration

vertexArray.connect()

vertexBuffer.connectTo(GlArrayBuffer)
program.formatAttributesWith():
    type
        Vertex = object
            pos: Vec[2, float32]

propertyBuffer.connectTo(GlArrayBuffer)
program.formatAttributesWith():
    type
        Properties {.instanced.} = object
            model: Mat[4, 4, float32]

indexBuffer.connectTo(GlElementArrayBuffer)

# data

vertexBuffer.connectTo(GlArrayBuffer)
GlArrayBuffer.allocateWith(vertices, usage)

propertyBuffer.connectTo(GlArrayBuffer)
GlArrayBuffer.allocateWith(properties, usage)

indexBuffer.connectTo(GlElementArrayBuffer)
GlElementArrayBuffer.allocateWith(indices, usage)

# draw

while not window.closeRequested:
    glClearColor(0f, 0f, 0f, 1f)
    glClear(GlColorBufferBit)

    program.connect()
    vertexArray.connect()

    glDrawElementsInstanced(GlTriangles, 6, GlUnsignedByte, nil, 1)

    window.swapBuffers()
    pollEvents()