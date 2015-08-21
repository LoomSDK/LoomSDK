attribute vec4 a_position;
attribute vec4 a_color0;
attribute vec2 a_texcoord0;

varying vec2 v_texcoord0;
varying vec4 v_color0;

uniform mat4 u_mvp;

void main()
{
    gl_Position = u_mvp * a_position;
    v_color0 = a_color0;
    v_texcoord0 = a_texcoord0;
}
