/* File generated with Shader Minifier 1.1.4
 * http://www.ctrl-alt-test.fr
 */
#ifndef POST_H_
# define POST_H_

const char *post_glsl =
 "uniform sampler2D B;"
 "uniform vec3 V;"
 "void main()"
 "{"
   "vec2 v=gl_FragCoord.xy/V.xy,s=vec2(.002*V.y/V.x,.002),z=vec2(0.,1.1),c;"
   "vec3 i=vec3(0.);"
   "vec4 r=texture2D(B,v),a=vec4(r.xyz,1.),t;"
   "int w=256;"
   "float x=4.,p=2.4,y=1.,e;"
   "mat2 m=mat2(cos(p),sin(p),-sin(p),cos(p));"
   "for(int f=0;f<w;f++)"
     "y+=1./y,z*=m,c=s*(y-1.)*z,t=texture2D(B,v+c),i+=t.xyz,e=length(c),a+=step(t.w,r.w)*vec4(t.xyz,1.)*step(e*.01,step(e,abs(t.w-x)/V.x));"
   "i=pow(i/float(w),vec3(2.))+a.xyz/a.w;"
   "gl_FragColor=vec4(pow(i/(i+1.),vec3(1./2.2)),1.);"
 "}";

#endif // POST_H_
