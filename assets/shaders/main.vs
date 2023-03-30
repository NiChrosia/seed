#version 430

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoords;

layout (location = 2) in mat4 aModel;

uniform mat4 view;
uniform mat4 proj;

out vec2 vTexCoords;

void main() {
	gl_Position = proj * view * aModel * vec4(aPos, 1.0);
	vTexCoords = aTexCoords;
}
