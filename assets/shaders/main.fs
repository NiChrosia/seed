#version 430

in vec2 vTexCoords;
in vec4 vTint;

uniform sampler2D atlas;

out vec4 fragColor;

void main() {
	fragColor = texture(atlas, vTexCoords);
	fragColor.rgb = (fragColor.rgb * (1.0 - vTint.a)) + (vTint.rgb * vTint.a);
}
