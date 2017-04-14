uniform sampler2D FB;
uniform vec2 V;

void main() {
	vec2 uv = gl_FragCoord.xy / V;
	vec3 color = texture2D(FB, uv).xyz;

	const int N = 128;
	const float GA = 2.399;
	mat2 rot = mat2(cos(GA),sin(GA),-sin(GA),cos(GA));
	vec3 bloom = vec3(0);
	vec2 pixel = vec2(.002*V.y/V.x,.002),angle=vec2(0,1.4);
	float rad=1.;
	for (int j=0;j<N;j++)
	{
		rad += 1./rad;
		angle*=rot;
		vec4 col=texture2D(FB,uv+pixel*(rad-1.)*angle);
		bloom+=col.xyz;
	}
	color += pow(bloom / float(N), vec3(2.));

	color = color / (color + 1.);
	gl_FragColor = vec4(pow(color, vec3(1./2.2)), 1.);
}

/*
void main() {
	vec2 uv = gl_FragCoord.xy / V;
	
	vec3 color = texture2D(FB, uv).xyz;

	color = color / (color + vec3(1.));
	color = pow(color, vec3(1./2.2));

	gl_FragColor = vec4(color, 1.);
}*/
