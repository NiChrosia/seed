import ./systems/[state, windows, controls, renderer], ./systems/drawers/polybatches
import staticglfw as glfw, opengl, vmath

windows.initialize("Gamma", ivec2(800, 600), (4, 3, true))

renderer.setup()
controls.setCallbacks()

renderer.polyBatch.rect("white", vec4(1f, 0f, 0f, 0.5f), vec2(0f), vec2(1f), translate(vec3(0f, 5f, 0f)))
renderer.polyBatch.poly(20, vec4(0f, 0.5f, 0.5f, 1f), 5f, translate(vec3(10f, 10f, 0f)))

# main loop
while windowShouldClose(window) == 0:
    glClearColor(0f, 0f, 0f, 1f)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    controls.update()
    renderer.draw()

    window.swapBuffers()
    pollEvents()

windows.terminate()
