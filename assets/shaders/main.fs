#version 430

in vec2 vTexCoords;

uniform sampler2D atlas;

out vec4 fragColor;

void main() {
	fragColor = texture(atlas, vTexCoords);
}
