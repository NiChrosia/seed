import buffers, vertex_arrays, shaders
import vmath, windy
import opengl

# window

let window = newWindow("Example", ivec2(800, 600), openglMajorVersion = 3, openglMinorVersion = 3)

window.makeContextCurrent()
loadExtensions()

# data

type
    Vertex = Vec2
    Properties = Vec4
    Index = uint8

proc size*[T](kind: typedesc[T]): int32 =
    return int32(sizeof(kind))

proc size[T](value: T): int32 =
    return int32(sizeof(value))

var vertices = [vec2(-1f, -1f), vec2(-1f, 1f), vec2(1f, -1f)]
var properties = vec4(0.3f, 0.2f, 0.2f, 1f)
var indices = [uint8(0), 1, 2]

# shaders

let vertexSource = """#version 330

in vec2 pos;
in vec4 color;

out vec4 vColor;

void main() {
    gl_Position = vec4(vec3(pos, 0.0), 1.0);
    vColor = color;
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

vertexArray.connect()

vertexBuffer.connectTo(GlArrayBuffer)
GlArrayBuffer.allocate(vertices.size(), usage)
GlArrayBuffer.insert(0, vertices.size(), addr vertices)

let pos = program.newAttributeIndex("pos")
setVector(pos, float32, 0, 2, 0)

propertyBuffer.connectTo(GlArrayBuffer)
GlArrayBuffer.allocate(properties.size(), usage)
GlArrayBuffer.insert(0, properties.size(), addr properties)

let color = program.newAttributeIndex("color")
setVector(color, float32, 0, 4, 0)
setDivisor(color, 1)

indexBuffer.connectTo(GlElementArrayBuffer)
GlElementArrayBuffer.allocate(indices.size(), usage)
GlElementArrayBuffer.insert(0, indices.size(), addr indices)

while not window.closeRequested:
    glClearColor(0f, 0f, 0f, 1f)
    glClear(GlColorBufferBit)

    program.connect()
    vertexArray.connect()

    glDrawElementsInstanced(GlTriangles, 3, GlUnsignedByte, nil, 1)

    window.swapBuffers()
    pollEvents()