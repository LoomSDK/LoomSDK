$input a_position, a_color0, a_texcoord0
$output v_texcoord0

#include "bgfx_shader.sh"
void main()
{
    vec3 wpos = instMul(u_nodeMatrix, vec4(a_position, 1.0) ).xyz;
    gl_Position = mul(u_viewProj, vec4(wpos, 1.0) );
    v_texcoord0 = a_texcoord0;    
}

