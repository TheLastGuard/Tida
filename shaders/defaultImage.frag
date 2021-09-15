#version 130
in vec2 fragTexCoord;

uniform vec4 color = vec4(1.0f, 1.0f, 1.0f, 1.0f);
uniform sampler2D texture;

void main()
{
    gl_FragColor = texture2D(texture, fragTexCoord) * color;
}
