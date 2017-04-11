#version 130
uniform float T;
uniform vec2 V;
uniform vec3 M;

const vec3 E = vec3(.0,1e-4,1.);
const float PI = 3.14159265359;

float hash(vec2 p){return fract(1e4*sin(17.*p.x+.1*p.y)*(.1+abs(sin(13.*p.y+p.x))));}
float hash(vec3 p){return hash(vec2(hash(p.xy), p.z));}
float noise(vec3 p){
	vec3 P=floor(p);p=p-P;
	p*=p*(3.-2.*p);
	return mix(
		mix(mix(hash(P      ), hash(P+E.zxx), p.x), mix(hash(P+E.xzx), hash(P+E.zzx), p.x), p.y),
		mix(mix(hash(P+E.xxz), hash(P+E.zxz), p.x), mix(hash(P+E.xzz), hash(P+E.zzz), p.x), p.y), p.z);
}

float map(vec3 p){
	vec3 offs = vec3(1., 1.75, .5); // Offset point.
	const vec2 a = sin(vec2(0, 1.57079632) + 1.57/2.);
	const mat2 m = mat2(a.y, -a.x, a);
	vec2 a2 = sin(vec2(0, 1.57079632) + 1.57/4. + T);
	mat2 m2 = mat2(a2.y, -a2.x, a2);
	const float s = 6.; // Scale factor.
	float d = 1e5; // Distance.
	//p  = abs(fract(p*.5)*2. - 1.); // Standard spacial repetition.
	float amp = 1./s; // Analogous to layer amplitude.
	for(int i=0; i<4; i++){
			p.xy = m*p.xy;
			p.yz = m2*p.yz;
			p = abs(p);
			//p.xy += step(p.x, p.y)*(p.yx - p.xy);
			p.xz += step(p.x, p.z)*(p.zx - p.xz);
			p.yz += step(p.y, p.z)*(p.zy - p.yz);
			p = p*s + offs*(1. - s);
			p.z -= step(p.z, offs.z*(1. - s)*.5)*offs.z*(1. - s);
			d = min(d, max(max(p.x, p.y), p.z)*amp);
			d = min(d, (length(p)-6.*amp));
			amp /= s; // Decrease the amplitude by the scaling factor.
	}
 	return d - .0035; // .35 is analous to the object size.
}

float box(vec3 p, vec3 s) {
	p = abs(p) - s;
	return max(p.x, max(p.y, p.z));
}

mat3 RX(float a){
	float s=sin(a),c=cos(a);
	return mat3(1.,0.,0.,0.,c,-s,0.,s,c);
}
mat3 RY(float a){
	float s=sin(a),c=cos(a);
	return mat3(c,0.,s,0.,1.,0,-s,0.,c);
}

mat3 RZ(float a){
	float s=sin(a),c=cos(a);
	return mat3(c,s,0.,-s,c,0.,0.,0.,1.);
}

float F(vec3 p) {
	p = RY(T) * p;
	const float scale = 2., rscale = 1. / scale;
	float w = 1e5;
	vec2 a1 = sin(vec2(0., PI/2.) + 2. + T);
	mat2 m1 = mat2(a1.y, -a1.x, a1);
	vec2 a2 = sin(vec2(0., PI/2.) + .1  - T);
	mat2 m2 = mat2(a2.y, -a2.x, a2);
	float bs = .3;

	float s = 1.;
	const int N = 4;
	for (int i = 0; i < N; ++i) {

		//p = abs(p);
		p.xy += step(p.x, p.y)*(p.yx - p.xy);
    p.xz += step(p.x, p.z)*(p.zx - p.xz);
    p.yz += step(p.y, p.z)*(p.zy - p.yz);
		p.yx = m2 * p.yx;
		p.zy = m1 * p.zy;

		vec2 ss = vec2(.5,2.) * s;
		float d = min(min(
			box(p, vec3(bs) * ss.yxx),
			box(p, vec3(bs) * ss.xyx)),
			box(p, vec3(bs) * ss.xxy));
		d = max(-d, box(p, vec3(bs) * s));
		w = min(w, d);

		p.x -= .3;
		p = p * scale;
		s *= rscale;
	}

	return w - .002;
}

//const float VR = 3.;
//float VR = 2.;//.2 + (sin(T*.1) + 1.) * 4.;

float F2(vec3 p) {
	p = RY(T*.1) * p;
	float S = 1.2;
	const int N = 4;
	mat3 M = RY(.3) * RZ(2.+.1*sin(T));
	vec3 off = (vec3(-.4,-1.4,-.7));
	p /= S;
	for (int i = 0; i < N; ++i) {
		p.xy += step(p.x, p.y)*(p.yx - p.xy);
    p.xz += step(p.x, p.z)*(p.zx - p.xz);
		p = abs(p);
    p.yz += step(p.y, p.z)*(p.zy - p.yz);
		p *= S;
		p += off;
		p = M * p;
	}
	//return (max(-box(p,vec3(.9,1e5,.9)*S), length(p) - S * 1.3) * (pow(1.3, -float(N)))) * S;
	return max(-box(p,vec3(.9,1e5,.9)*S), length(p) - S * 1.3) * pow(S, -float(N));
}

float F3(vec3 p) {
	p = RY(T*.1) * p;
	const float S = 3.;
	const int N = 8;
	vec3 C = vec3(1.,1.9,1.1);
	for (int i = 0; i < N; ++i) {
		p = p * RY(.1);
		p = abs(p);
		p.xy += step(p.x, p.y)*(p.yx - p.xy);
    p.xz += step(p.x, p.z)*(p.zx - p.xz);
    p.yz += step(p.y, p.z)*(p.zy - p.yz);
		p = p * RZ(.1);
		p.xy = mix(p.xy, C.xy, S);
		//p.x = S * p.x - C.x * (S - 1.);
		//p.y = S * p.y - C.y * (S - 1.);
		//p.z = S * p.z - C.z * (S - 1.);
		p.z = S * p.z;
		if (p.z > .5 * C.z * (S - 1.))
			p.z -= C.z * (S - 1.);
	}
	//return (length(p) - 2.) * pow(S, -float(N));
	return box(p, vec3(2.)) * pow(S, -float(N));
}

float F4(vec3 p) {
	p = RY(T*.1) * p;
	const float S = 2.8;
	const int N = 5;
	vec3 C = vec3(1.,.9,1.1);
	for (int i = 0; i < N; ++i) {
		p = p * RY(.1+T*.3);
		p = abs(p);
		p.xy += step(p.x, p.y)*(p.yx - p.xy);
    p.xz += step(p.x, p.z)*(p.zx - p.xz);
    p.yz += step(p.y, p.z)*(p.zy - p.yz);
		p = p * RZ(.1);
		p.xy = p.xy * S - (S - 1.) * C.xy;
		//p.x = S * p.x - C.x * (S - 1.);
		//p.y = S * p.y - C.y * (S - 1.);
		//p.z = S * p.z - C.z * (S - 1.);
		p.z = S * p.z;
		if (p.z > .5 * C.z * (S - 1.))
			p.z -= C.z * (S - 1.);
	}
	//return (length(p) - 2.) * pow(S, -float(N));
	return box(p, vec3(1.)) * pow(S, -float(N));
}

float ball(vec3 p, float r) { return length(p) - r; }
vec3 rep(vec3 p, vec3 r) { return mod(p,r) - r*.5; }
float ring(vec3 p, float r, float R, float t) {
	float pr = length(p);
	return max(abs(p.y)-t, max(pr - R, r - pr));
}
float vmax(vec2 p) { return max(p.x, p.y); }

float path(vec3 p) {
	float flr = vmax(abs(p.xy) - vec2(2.,.1));
	p.x = abs(p.x)+.02;
	float rls = vmax(abs(p.xy-vec2(2.,1.)) - vec2(.02));
	float rlst = max(abs(mod(p.z,.4)-.2)-.02, max(abs(p.y-.5)-.5, abs(p.x-2.)-.02));
	return min(flr, min(rls, rlst));
}

float hole(vec3 p) {
	return box(p-vec3(33.,1.6,0.), vec3(20.,1.5,1.96));
}

float room(vec3 p) {
	float holes = -min(hole(vec3(abs(p.x), p.yz)), hole(vec3(abs(p.z), p.yx)));;
	float boxes = max(-ball(p,19.), box(rep(p, vec3(2.)), vec3(.8)));
	float extwall = -ball(p,20.);
	float wall = max(holes, min(extwall, boxes));

	//float rings = ring(vec3(p.x, abs(p.y)-3., p.z), 8., 9., .4);
	float rings = ball(p,9.);
	rings = max(rings, abs(abs(p.y)-3.)-.5);
	rings = min(rings, box(rep(p,vec3(11.8)), vec3(.1, 100., .1)));
	rings = max(rings, -ball(p,8.9));
	//rings = min(rings+.02, max(rings, box(rep(p,vec3(.4)),vec3(.2))));
	float paths = path(vec3(length(p.xz)-13., p.y, atan(p.x, p.z)*10.));
	paths = min(paths, max(15.-length(p.xz), min(path(p.zyx), path(p))));
	paths = max(paths, holes);
	/*float rails = min(
		ring(p - E.xzx*1., 10.-.02, 10.+.02, .02),
		ring(p - E.xzx*1., 15.-.02, 15.+.02, .02));
	float ring = ring(p, 10., 15., .1);*/
	float scene = wall;
	scene = min(scene, rings);
	scene = min(scene, paths);
	return scene;
}

float W(vec3 p) {
	float kifs = F4(p/4.);
	float room = room(p);
	return min(kifs, room);
}

vec3 N(vec3 p) {
	float w=W(p);
	return normalize(vec3(W(p+E.yxx)-w,W(p+E.xyx)-w,W(p+E.xxy)-w));
}

void MT(vec3 p, out vec3 albedo, out float roughness) {
	if (p.y < -.9) albedo = vec3(1.); else {
		if (p.x < -.9) albedo = vec3(1.,0.,0.); else
		if (p.x > .9) albedo = vec3(0.,0.,1.); else
		albedo = vec3(0.,1.,0.);
	}
	roughness = 1.;
	//roughness = min(1.,.1+pow(noise(p*3.), 4.));
}

const float ML = 40.;
#define LN 3
vec3 LP[3], LC[3];
vec3 trace(vec3 o, vec3 d) {
	vec3 p,n;
	float l = 0.;
	for (int i = 0; i < 164; ++i) {
		p = o+d*l;
		float w = W(p);
		l += w;
		if (w < .001*l || l > ML) break;
	}

	if (l > ML) return vec3(.0);

	vec3 albedo = vec3(1.);
	n = N(p);
	d = -d;

#if 1
	p += n * .01;
	vec3 c = vec3(.01);
	for(int i = 0; i < LN; ++i) {
		vec3 L = LP[i] - p;
		float shadow = 1.;
#if 1
		const int SS = 32;
		for (int j = 0; j < SS; ++j) {
		/* FIXME */
			float w=W(p + L * float(j+1) / float(SS));
			shadow = min(shadow, w);
		}
		//if (shadow < .01) break;
		shadow = pow(max(0.,shadow), .3);
#endif

		float dL = max(0.,dot(n,normalize(L)));
		c += albedo * shadow * dL * LC[i] / dot(L,L);
	}
#else
	vec3 c = vec3(.05) + .95 * max(0., dot(n,normalize(vec3(1.))));
#endif


	return c;
}

void main() {
	vec2 uv = gl_FragCoord.xy / V * 2. - 1.;
	uv.x *= V.x / V.y;

	LP[0] = vec3(5.*sin(T), 5., 5.*cos(T));
	LP[1] = vec3(5.*sin(-T+3.), 5., 5.*cos(T+3.));
	LP[2] = vec3(5.*sin(-T*.4+3.), 9.*sin(T*.7), 5.*cos(T*.5+3.));
	LC[0] = vec3(10.);
	LC[1] = vec3(9.,10.,5.);
	LC[2] = vec3(14.,7.,3.);

	mat3 ML = RY(M.x*2e-3) * RX(M.y*2e-3);
	vec3 O = ML * vec3(0., 0., max(.1, M.z/10.));
	vec3 D = ML * normalize(vec3(uv, -1.44));

	vec3 color = trace(O, D);

	color = color / (color + vec3(1.0));
	color = pow(color, vec3(1.0/2.2));

	gl_FragColor = vec4(color, 1.);
	//gl_FragColor = vec4(sin(T*10.));
}
