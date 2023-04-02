import ./systems/[state, windows, controls, renderer], ./systems/drawers/quads
import staticglfw as glfw, opengl, vmath

windows.initialize("Gamma", ivec2(800, 600), (4, 3, true))

renderer.setup()
controls.setCallbacks()

renderer.quadBatch.square("white", vec2(1f), mat4())
renderer.quadBatch.quad([vec3(-1f, -1f, 0f), vec3(-1f, 0f, 0f), vec3(1f, 1f, 0f), vec3(1f, 0f, 0f)], [vec2(0f, 0f), vec2(0f, 1f), vec2(1f, 1f), vec2(1f, 0f)], "white", translate(vec3(-5f, 0f, -1f)))

# main loop
while windowShouldClose(window) == 0:
    glClearColor(0f, 0f, 0f, 1f)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    controls.update()
    renderer.draw()

    window.swapBuffers()
    pollEvents()

windows.terminate()
