import ./api/[windows], ./api/rendering/cameras
import ./systems/[state, controls, renderer], ./systems/drawers/polybatches
import staticglfw as glfw, opengl, vmath

if glfw.init() == 0:
    raise Exception.newException("Failed to initalize GLFW!")

twindow = TrackingWindow.init("Gamma", ivec2(800, 600), (4, 3, true))

var control = Control.init(cameraSpeed = 0.1f)
var renderer3 = Renderer3.init()

var camera = Camera3.init(position = vec3(-5f, 0f, 0f))

renderer3.polyBatch.rect("white", vec4(1f, 0f, 0f, 0.5f), vec2(0f), vec2(1f), translate(vec3(0f, 5f, 0f)))
renderer3.polyBatch.poly(20, vec4(0f, 0.5f, 0.5f, 1f), 5f, translate(vec3(10f, 10f, 0f)))
renderer3.polyBatch.poly(3, vec4(0f, 0.5f, 0.5f, 1f), 5f, translate(vec3(-10f, -10f, 0f)))

while not twindow.shouldClose:
    glClearColor(0f, 0f, 0f, 1f)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    control.update(camera)

    renderer3.polyBatch.flush()
    renderer3.draw(camera)

    twindow.window.swapBuffers()
    pollEvents()

twindow.terminate()
glfw.terminate()
