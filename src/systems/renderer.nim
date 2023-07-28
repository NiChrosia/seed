import ../api/gl/[textures, shaders, ssbos, uniforms], ../api/rendering/[atlases, cameras], "."/[state], drawers/[polybatches], ../assets
import opengl, vmath

var
    program: GLuint
    atlasTexture: GLuint

    modelBuffer: Ssbo
    polyBatch*: PolyBatch

proc setup*() =
    block shaderSetup:
        let vs = glCreateShader(GL_VERTEX_SHADER)
        let fs = glCreateShader(GL_FRAGMENT_SHADER)
        program = glCreateProgram()

        vs.compile(getAsset("assets/shaders/main.vs"))
        fs.compile(getAsset("assets/shaders/main.fs"))

        glAttachShader(program, vs)
        glAttachShader(program, fs)

        program.link()

    block atlasSetup:
        atlas = Atlas.setup(4096)
        var atlasImage = atlas.image

        atlasTexture = createTexture(GL_TEXTURE_2D)
        atlasTexture.wrap2(GL_CLAMP_TO_EDGE)
        atlasTexture.filter2(GL_LINEAR)

        glTextureStorage2D(atlasTexture, 1, GL_RGBA8, 4096, 4096)
        glTextureSubImage2D(atlasTexture, 0, 0, 0, 4096, 4096, GL_RGBA, GL_UNSIGNED_BYTE, addr atlasImage.data[0])
        # uniforms
        let projMatrix = perspective(90f, float32(twindow.size.x) / float32(twindow.size.y), 0.1f, 1000f)
        program.setMat4("proj", projMatrix)

        glUseProgram(program)

        glBindTextureUnit(0, atlasTexture)

    # ubo
    modelBuffer = Ssbo.init(GL_DYNAMIC_DRAW, 0)
    modelBuffer.attach(program, "Models")

    polyBatch = PolyBatch.init(addr atlas, addr modelBuffer)
    
    # camera
    camera = Camera3.init(position = vec3(-5f, 0f, 0f))

proc draw*() =
    program.setMat4("view", camera.matrix)

    glUseProgram(program)

    # drawers
    polyBatch.draw()
