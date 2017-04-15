uniform sampler2D FB;
uniform vec2 V;
uniform float TPCT;

void main() {
	if (gl_FragCoord.y < 10.) {
		gl_FragColor = vec4(step(gl_FragCoord.x / V.x, TPCT));
		return;
	}
	vec2 uv = gl_FragCoord.xy / V;
	vec3 color = texture2D(FB, uv).xyz;
	gl_FragColor = vec4(color, 1.);
}
