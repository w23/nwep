uniform sampler2D B;
uniform vec3 V, D;

void main() {
	vec2 uv = gl_FragCoord.xy / V.xy, pixel = vec2(.002*V.y/V.x,.002), angle=vec2(0.,1.1), off;
	vec3 color = vec3(0.);
	vec4 pix = texture2D(B, uv), dof = vec4(pix.xyz, 1.), smpl;

	int N = 256;
	float focus = D.z, GA = 2.4, rad = 1., r;
	mat2 rot = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));
	for (int i=0;i<N;i++) {
		rad += 1./rad;
		angle*=rot;
		off = pixel*(rad-1.)*angle;
		smpl = texture2D(B,uv+off);
		color += smpl.xyz;
			r = length(off);
			dof += step(smpl.w,pix.w)*vec4(smpl.xyz, 1.) * step(r*.01, step(r, abs(smpl.w - focus) * 1. / V.x));
	}
	color = pow(color / float(N), vec3(2.)) +  dof.xyz / dof.w;
	gl_FragColor = vec4(pow(color / (color + 1.), vec3(1./2.2)), 1.);
}
