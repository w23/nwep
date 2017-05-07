/* File generated with Shader Minifier 1.1.4
 * http://www.ctrl-alt-test.fr
 */
#ifndef POST_H_
# define POST_H_

const char *post_glsl =
 "uniform sampler2D B;"
 "uniform vec3 V,D;"
 "void main()"
 "{"
   "vec2 v=gl_FragCoord.xy/V.xy,c=.002*vec2(V.y/V.x,1.),f=vec2(0.,1.1);"
   "vec4 r=vec4(0.);"
   "float i=0.;"
   "mat2 m=mat2(cos(2.4),sin(2.4),-sin(2.4),cos(2.4));"
   "for(int s=0;s<256;s++)"
     "{"
       "vec4 a=texture2D(B,v+c*i*f);"
       "if(abs(50.*(D.z-a.w)/a.w/(D.z-.5))>i)"
         "r+=vec4(a.xyz,1.);"
       "i+=1./(i+1.);"
       "f*=m;"
     "}"
   "gl_FragColor=vec4(pow(r.xyz/(r.xyz+r.w),vec3(1./2.2)),1.);"
 "}";

#endif // POST_H_
