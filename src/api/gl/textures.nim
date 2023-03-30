import opengl

# init
proc createTexture*(kind: GLenum): GLuint =
    glCreateTextures(kind, 1, addr result)

# wrapping
# - default functions
proc wrap*(texture: GLuint, s: GLint) {.inline.} =
    glTextureParameteri(texture, GL_TEXTURE_WRAP_S, s)

proc wrap*(texture: GLuint, s, t: GLint) {.inline.} =
    texture.wrap(s)
    glTextureParameteri(texture, GL_TEXTURE_WRAP_T, t)

proc wrap*(texture: GLuint, s, t, r: GLint) {.inline.} =
    texture.wrap(s, t)
    glTextureParameteri(texture, GL_TEXTURE_WRAP_R, r)

# - shorthand variants
proc wrap2*(texture: GLuint, both: GLint) {.inline.} =
    texture.wrap(both, both)

proc wrap3*(texture: GLuint, allThree: GLint) {.inline.} =
    texture.wrap(allThree, allThree, allThree)

# filter
# - default
proc filter*(texture: GLuint, min, mag: GLint) {.inline.} =
    glTextureParameteri(texture, GL_TEXTURE_MIN_FILTER, min)
    glTextureParameteri(texture, GL_TEXTURE_MAG_FILTER, mag)

# - shorthand
proc filter2*(texture: GLuint, both: GLint) {.inline.} =
    texture.filter(both, both)
