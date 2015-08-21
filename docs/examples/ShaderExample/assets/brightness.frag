varying vec2 v_texcoord0;
varying vec4 v_color0;

uniform sampler2D u_texture;
uniform float u_intensity;

void main()
{
    vec4 c = texture2D(u_texture, v_texcoord0);
    gl_FragColor = vec4(clamp(vec3(abs(c)) + u_intensity, 0.0, 1.0), c.a) * v_color0;
}
