/* File generated with Shader Minifier 1.1.4
* http://www.ctrl-alt-test.fr
*/
const char *post_glsl =
"uniform sampler2D FB;"
"uniform vec2 V;"
"void main()"
"{"
"vec2 v=gl_FragCoord.rg/V,s=vec2(.002*V.g/V.r,.002),b=vec2(0.,1.1),a;"
"vec3 g=vec3(0.);"
"vec4 F=texture2D(FB,v),r=vec4(F.rgb,1.),t;"
"int c=256;"
"float m=4.,i=2.4,B=1.,p;"
"mat2 l=mat2(cos(i),sin(i),-sin(i),cos(i));"
"for(int f=0;f<c;f++)"
"B+=1./B,b*=l,a=s*(B-1.)*b,t=texture2D(FB,v+a),g+=t.rgb,p=length(a),r+=step(t.a,F.a)*vec4(t.rgb,1.)*step(p*.01,step(p,abs(t.a-m)/V.r));"
"g=pow(g/float(c),vec3(2.))+r.rgb/r.a;"
"gl_FragColor=vec4(pow(g/(g+1.),vec3(1./2.2)),1.);"
"}";
