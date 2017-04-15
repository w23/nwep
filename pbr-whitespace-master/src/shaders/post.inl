/* File generated with Shader Minifier 1.1.4
 * http://www.ctrl-alt-test.fr
 */
#ifndef POST_INL_
# define POST_INL_
# define VAR_FB "z"
# define VAR_T "v"
# define VAR_V "f"

const char *post_glsl =
 "uniform sampler2D z;"
 "uniform vec2 f;"
 "uniform float v;"
 "void main()"
 "{"
   "vec2 v=gl_FragCoord.xy/f;"
   "vec4 i=texture2D(z,v);"
   "vec3 c=vec3(0.);"
   "float s=2.;"
   "const int w=256;"
   "const float r=2.399;"
   "mat2 t=mat2(cos(r),sin(r),-sin(r),cos(r));"
   "vec3 m=vec3(0.);"
   "vec4 u=vec4(i.xyz,1.);"
   "vec2 a=vec2(.002*f.y/f.x,.002),g=vec2(0.,1.1);"
   "float p=1.;"
   "for(int e=0;e<w;e++)"
     "{"
       "p+=1./p;"
       "g*=t;"
       "vec2 o=a*(p-1.)*g;"
       "vec4 l=texture2D(z,v+o);"
       "m+=l.xyz;"
       "if(l.w<i.w)"
         "{"
           "float x=length(o),n=abs(l.w-s)/f.x,y=step(x,n);"
           "y=step(x*.01,y);"
           "u+=vec4(l.xyz,1.)*y;"
         "}"
     "}"
   "c+=pow(m/float(w),vec3(2.));"
   "c+=u.xyz/u.w;"
   "c=c/(c+1.);"
   "gl_FragColor=vec4(pow(c,vec3(1./2.2)),1.);"
 "}";

#endif // POST_INL_
