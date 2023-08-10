import ../api/gl/[textures, shaders, ssbos, uniforms], ../api/rendering/[atlases, cameras], "."/[state], drawers/[polybatches], ../assets
import opengl, vmath

type
    Renderer3* = object
        program: GLuint
        atlasTexture: GLuint

        modelBuffer: Ssbo
        polyBatch*: PolyBatch

proc init*(_: typedesc[Renderer3]): Renderer3 =
    block shaderSetup:
        let vs = glCreateShader(GL_VERTEX_SHADER)
        let fs = glCreateShader(GL_FRAGMENT_SHADER)
        result.program = glCreateProgram()

        vs.compile(getAsset("assets/shaders/main.vs"))
        fs.compile(getAsset("assets/shaders/main.fs"))

        glAttachShader(result.program, vs)
        glAttachShader(result.program, fs)

        result.program.link()

    block atlasSetup:
        atlas = Atlas.setup(4096)
        var atlasImage = atlas.image

        result.atlasTexture = createTexture(GL_TEXTURE_2D)
        result.atlasTexture.wrap2(GL_CLAMP_TO_EDGE)
        result.atlasTexture.filter2(GL_LINEAR)

        glTextureStorage2D(result.atlasTexture, 1, GL_RGBA8, 4096, 4096)
        glTextureSubImage2D(result.atlasTexture, 0, 0, 0, 4096, 4096, GL_RGBA, GL_UNSIGNED_BYTE, addr atlasImage.data[0])
        # uniforms
        let projMatrix = perspective(90f, float32(twindow.size.x) / float32(twindow.size.y), 0.1f, 1000f)
        result.program.setMat4("proj", projMatrix)

        glUseProgram(result.program)

        glBindTextureUnit(0, result.atlasTexture)

    # ubo
    result.modelBuffer = Ssbo.init(GL_DYNAMIC_DRAW, 0)
    result.modelBuffer.attach(result.program, "Models")

    result.polyBatch = PolyBatch.init(addr atlas, addr result.modelBuffer)

proc draw*(renderer: Renderer3, camera: Camera3) =
    renderer.program.setMat4("view", camera.matrix)

    glUseProgram(renderer.program)

    # drawers
    renderer.polyBatch.draw()
