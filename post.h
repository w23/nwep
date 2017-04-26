/* File generated with Shader Minifier 1.1.4
 * http://www.ctrl-alt-test.fr
 */
#ifndef POST_H_
# define POST_H_

const char *post_glsl =
 "uniform sampler2D FB;"
 "uniform vec2 V;"
 "void main()"
 "{"
   "vec2 v=gl_FragCoord.xy/V,s=vec2(.002*V.y/V.x,.002),z=vec2(0.,1.1),c;"
   "vec3 F=vec3(0.);"
   "vec4 r=texture2D(FB,v),a=vec4(r.xyz,1.),t;"
   "int w=256;"
   "float x=4.,i=2.4,B=1.,p;"
   "mat2 m=mat2(cos(i),sin(i),-sin(i),cos(i));"
   "for(int f=0;f<w;f++)"
     "B+=1./B,z*=m,c=s*(B-1.)*z,t=texture2D(FB,v+c),F+=t.xyz,p=length(c),a+=step(t.w,r.w)*vec4(t.xyz,1.)*step(p*.01,step(p,abs(t.w-x)/V.x));"
   "F=pow(F/float(w),vec3(2.))+a.xyz/a.w;"
   "gl_FragColor=vec4(pow(F/(F+1.),vec3(1./2.2)),1.);"
 "}";

#endif // POST_H_
