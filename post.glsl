uniform sampler2D FB;
uniform vec2 V;
uniform float T;

void main() {
	vec2 uv = gl_FragCoord.xy / V;
	vec4 pix = texture2D(FB, uv);
	vec3 color = vec3(0.);

	float focus = 15.+8.*sin(T);
	const int N = 2*128;
	const float GA = 2.399;
	mat2 rot = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));
	vec3 bloom = vec3(0.);
	vec4 dof = vec4(pix.xyz, 1.);
	vec2 pixel = vec2(.002*V.y/V.x,.002),angle=vec2(0.,1.1);
	float rad=1.;
	for (int i=0;i<N;i++) {
		rad += 1./rad;
		angle*=rot;
		vec2 off = pixel*(rad-1.)*angle;
		vec4 smpl = texture2D(FB,uv+off);
		bloom += smpl.xyz;
		//if (smpl.w < pix.w)
		{
			float r = length(off);
			float coc = abs(smpl.w - focus) * 1. / V.x;
			float doff = step(r, coc);
			doff = step(r*.01, doff);
			dof += vec4(smpl.xyz, 1.) * doff;
		}
	}
	color += pow(bloom / float(N), vec3(2.));
	color += dof.xyz / dof.w;

	color = color / (color + 1.);
	//color = mix(color, vec3(1.,0.,0.), step(abs(pix.w-focus),.1));
	gl_FragColor = vec4(pow(color, vec3(1./2.2)), 1.);
	//gl_FragColor = vec4(pix.w)/20.;
}
