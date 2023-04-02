#version 430

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoords;

layout (location = 2) in int aModelIndex;

uniform mat4 view;
uniform mat4 proj;

layout (std430, binding = 0) buffer Models {
	mat4 models[];
};

out vec2 vTexCoords;

void main() {
	gl_Position = proj * view * models[aModelIndex] * vec4(aPos, 1.0);
	vTexCoords = aTexCoords;
}
