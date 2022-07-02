import seed/video/backends/gl, opengl, std/strformat

let vertices = @[
    -0.5f, -0.5f, 0f, # bottom-left
    0.5f,  -0.5f, 0f, # bottom-right
    0f,    0.5f,  0f  # top
]

let colors = @[
    1f, 0f, 0f, # bottom-left
    0f, 1f, 0f, # bottom-right
    0f, 0f, 1f  # top
]

let inputs = newInputs(("aPos", 3), ("aColor", 3))

# manual creation to avoid registering handles
let buffer = new(VertexBuffer)
buffer.kind = GL_ARRAY_BUFFER
buffer.inputs = inputs

let packed = buffer.pack(@[vertices, colors])
let intended = @[
    # vertices    # colors
    -0.5f, -0.5f, 0f, 1f, 0f, 0f, # bottom-left
    0.5f,  -0.5f, 0f, 0f, 1f, 0f, # bottom-right
    0f,    0.5f,  0f, 0f, 0f, 1f  # top
]

assert packed == intended, &"Packed data ({packed}) did not match intended output! ({intended})"