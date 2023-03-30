import ./systems/[state, windows, controls, drawing], ./systems/drawers/squares
import staticglfw as glfw, opengl, vmath

windows.initialize("Gamma", ivec2(800, 600), (4, 3, true))

drawing.setup()
controls.setCallbacks()

# main loop
while windowShouldClose(window) == 0:
    glClearColor(0f, 0f, 0f, 1f)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    controls.update()
    drawing.draw()

    window.swapBuffers()
    pollEvents()

windows.terminate()
