uniform sampler2D FB;
uniform vec2 V;

void main() {
	vec2 uv = gl_FragCoord.xy / V;
	vec3 color = texture2D(FB, uv).xyz;
	gl_FragColor = vec4(color, 1.);
}
