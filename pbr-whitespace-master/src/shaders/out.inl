/* File generated with Shader Minifier 1.1.4
 * http://www.ctrl-alt-test.fr
 */
#ifndef OUT_INL_
# define OUT_INL_
# define VAR_FB "g"
# define VAR_TPCT "v"
# define VAR_V "d"

const char *out_glsl =
 "uniform sampler2D g;"
 "uniform vec2 d;"
 "uniform float v;"
 "void main()"
 "{"
   "if(gl_FragCoord.y<10.)"
     "{"
       "gl_FragColor=vec4(step(gl_FragCoord.x/d.x,v));"
       "return;"
     "}"
   "vec2 r=gl_FragCoord.xy/d;"
   "vec3 s=texture2D(g,r).xyz;"
   "gl_FragColor=vec4(s,1.);"
 "}";

#endif // OUT_INL_
