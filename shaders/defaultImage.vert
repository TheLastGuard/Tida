#version 130
in vec3 position;
in vec2 texCoord;

uniform mat4 projection;
uniform mat4 model;

out vec2 fragTexCoord;

void main()
{
    gl_Position = projection * model * vec4(position.xy, 0.0, 1.0);
    fragTexCoord = texCoord;
}
