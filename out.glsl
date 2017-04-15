uniform sampler2D FB;
uniform vec2 V;
//DEBUG uniform float TPCT;

void main() {
	// DEBUG if (gl_FragCoord.y < 10.) { gl_FragColor = vec4(step(gl_FragCoord.x / V.x, TPCT)); return; }
	gl_FragColor = texture2D(FB, gl_FragCoord.xy / V);
}
