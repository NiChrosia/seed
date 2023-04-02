import ../api/gl/[textures, shaders], ../api/rendering/[atlases, cameras], "."/[state], drawers/[squares], ../assets
import opengl, vmath

var
    program: GLuint
    atlasTexture: GLuint

proc setup*() =
    # shaders
    let vs = glCreateShader(GL_VERTEX_SHADER)
    let fs = glCreateShader(GL_FRAGMENT_SHADER)
    program = glCreateProgram()

    vs.compile(getAssetToStr("assets/shaders/main.vs"))
    fs.compile(getAssetToStr("assets/shaders/main.fs"))

    glAttachShader(program, vs)
    glAttachShader(program, fs)

    program.link()

    # atlas
    atlas = Atlas.setup(4096)
    var atlasImage = atlas.image

    atlasTexture = createTexture(GL_TEXTURE_2D)
    atlasTexture.wrap2(GL_CLAMP_TO_EDGE)
    atlasTexture.filter2(GL_LINEAR)

    glTextureStorage2D(atlasTexture, 1, GL_RGBA8, 4096, 4096)
    glTextureSubImage2D(atlasTexture, 0, 0, 0, 4096, 4096, GL_RGBA, GL_UNSIGNED_BYTE, addr atlasImage.data[0])
    # uniforms
    let proj = glGetUniformLocation(program, "proj")
    let projMatrix = perspective(90f, float32(WINDOW_SIZE.x) / float32(WINDOW_SIZE.y), 0.1f, 1000f)

    glUseProgram(program)

    glBindTextureUnit(0, atlasTexture)
    glProgramUniformMatrix4fv(program, proj, 1, false, unsafeAddr projMatrix[0, 0])

    # drawers
    squares.setup()

proc draw*() =
    # uniforms
    let view = glGetUniformLocation(program, "view")
    let viewMatrix = camera.matrix

    glUseProgram(program)

    glUniformMatrix4fv(view, 1, false, unsafeAddr viewMatrix[0, 0])

    # drawers
    squares.draw(program)
