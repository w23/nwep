uniform float T;
uniform vec2 V;
//uniform vec3 M;

const vec3 E = vec3(.0,1e-3,1.);
const float PI = 3.14159265359;

float hash1(float v){return fract(sin(v)*43758.5); }
float hash2(vec2 p){return fract(1e4*sin(17.*p.x+.1*p.y)*(.1+abs(sin(13.*p.y+p.x))));}
//float hash3(vec3 p){return hash2(vec2(hash2(p.xy), p.z));}
float noise2(vec2 p){
	vec2 P=floor(p);p-=P;
	p*=p*(3.-2.*p);
	return mix(mix(hash2(P), hash2(P+E.zx), p.x), mix(hash2(P+E.xz), hash2(P+E.zz), p.x), p.y);
}
/*float noise3(vec3 p){
	vec3 P=floor(p);p-=P;
	p*=p*(3.-2.*p);
	return mix(
		mix(mix(hash3(P      ), hash3(P+E.zxx), p.x), mix(hash3(P+E.xzx), hash3(P+E.zzx), p.x), p.y),
		mix(mix(hash3(P+E.xxz), hash3(P+E.zxz), p.x), mix(hash3(P+E.xzz), hash3(P+E.zzz), p.x), p.y), p.z);
}
*/
float noise(float p){
	float P = floor(p); p -= P;
	//p*=p*(3.-2.*p);
	return mix(hash1(P), hash1(P+1.), p);
}

//float box2(vec2 p, vec2 s) { p = abs(p) - s; return max(p.x, p.y); }
float box3(vec3 p, vec3 s) { p = abs(p) - s; return max(p.x, max(p.y, p.z)); }
//mat3 RX(float a){ float s=sin(a),c=cos(a); return mat3(1.,0.,0.,0.,c,-s,0.,s,c); }
mat3 RY(float a){	float s=sin(a),c=cos(a); return mat3(c,0.,s,0.,1.,0,-s,0.,c); }
//mat3 RZ(float a){ float s=sin(a),c=cos(a); return mat3(c,s,0.,-s,c,0.,0.,0.,1.); }

float ball(vec3 p, float r) { return length(p) - r; }
vec3 rep3(vec3 p, vec3 r) { return mod(p,r) - r*.5; }
//vec2 rep2(vec2 p, vec2 r) { return mod(p,r) - r*.5; }
float ring(vec3 p, float r, float R, float t) {
	float pr = length(p);
	return max(abs(p.y)-t, max(pr - R, r - pr));
}
float vmax(vec2 p) { return max(p.x, p.y); }

float F4(vec3 p) {
	p = RY(T*.1) * p;
	const float S = 2.8;
	const int N = 5;
	vec3 C = vec3(1.1,.9,1.9);
	for (int i = 0; i < N; ++i) {
		p = p * RY(.1+T*.3);
		p = abs(p);
		p.xy += step(p.x, p.y)*(p.yx - p.xy);
    p.xz += step(p.x, p.z)*(p.zx - p.xz);
    p.yz += step(p.y, p.z)*(p.zy - p.yz);
		p = p * RY(.7);
		p.xy = p.xy * S - (S - 1.) * C.xy;
		p.z = S * p.z;
		if (p.z > .5 * C.z * (S - 1.))
			p.z -= C.z * (S - 1.);
	}
	//return (length(p) - 2.) * pow(S, -float(N));
	return box3(p, vec3(1.)) * pow(S, -float(N));
}

bool dlight = true, detail = false;
int mindex = 0;

#define PICK(d, dn, mn) if(detail){if(dn<d){d=dn;mindex=mn;}}else d=min(d,dn);

float path(vec3 p) {
	float flr = vmax(abs(p.xy) - vec2(2.,.1));
	if (detail)
		//flr = flr+max(0.,.2*box2(rep2(p.xz,vec2(.1)), vec2(.01)));
		flr = flr+max(0.,.2*box3(rep3(p,vec3(.15)), vec3(.01)));
	p.x = abs(p.x)+.02;
	float rls = vmax(abs(p.xy-vec2(2.,1.)) - vec2(.02));
	float rlst = max(abs(mod(p.z,.4)-.2)-.02, max(abs(p.y-.5)-.5, abs(p.x-2.)-.02));
	return min(flr, min(rls, rlst));
}
float hole(vec3 p) { return box3(p-vec3(33.,1.6,0.), vec3(20.,1.5,1.96)); }

#define LN 5
vec3 LP[LN], LC[LN];

float W(vec3 p) {
	float w = 1e5;
	if (dlight)
		for (int i = 0; i < LN; ++i)
			PICK(w, length(p - LP[i]) - .1, i+100);

	float r2 = length(p.xz), a2 = atan(p.x, p.z);
	float r3 = length(p);

	float holes = -min(hole(vec3(abs(p.x), p.yz)), hole(vec3(abs(p.z), p.yx)));;
	float plates = max(-ball(p,19.), box3(rep3(p, vec3(2.)), vec3(.8)));
	float extwall = -ball(p,20.);
	PICK(w, extwall, 1);
	PICK(w, plates, 2);
	w = max(holes, w);

	float rings = ball(p,9.);
	rings = max(rings, abs(abs(p.y)-3.)-.5);
	//rings = max(rings, -box2(rep2(vec2(a2*4.,p.y*.2), vec2(.4)), vec2(.08)));
	//if (detail) rings -= .1*noise3(floor(p*10.));
	rings = min(rings, box3(rep3(p,vec3(11.8)), vec3(.1, 100., .1)));
	rings = max(rings, -ball(p,8.9));

	float paths = path(vec3(r2-13., p.y, a2*10.));
	paths = min(paths, max(15.-r2, min(path(p.zyx), path(p))));
	paths = max(paths, holes);

	PICK(w, rings, 3);
	PICK(w, paths, 4);
	if (T > 44.) {
		if (r3 < 8.) {
			float s = mix(.001, 4., smoothstep(44., 54., T));
			PICK(w, F4(p/s)*s, 5);
		} else
			w = min(w, r3 + 2.);
	}

	return w;
}

vec3 N(vec3 p) {
	float w=W(p);
	return normalize(vec3(W(p+E.yxx)-w,W(p+E.xyx)-w,W(p+E.xxy)-w));
}

void material(vec3 p, out vec3 n, out vec3 em, out vec3 a, out float r, out float m) {
	detail = true;
	n = N(p);
	em = vec3(0.,1.,1.);
	a = vec3(0.);
	r = 0.;
	m = .99;

	if (mindex == 1) {
		em = vec3(0.);
		a = vec3(1.);
		r = .5;
	} else if (mindex == 2) {
		float el = sin(T + dot(normalize(vec3(1.)), floor(p/2.)));
		a = max(0.,el) * vec3(1.);
		em = vec3(0.);
		r = .2;
	} else if (mindex == 3) {
		em = vec3(0.);
		a = vec3(1.);
		r = .8;
	} else if (mindex == 4) {
		em = vec3(0.);
		a = vec3(.56, .57, .58);
		m = .8;
		r = .2 + .6 * pow(noise2(p.xz*4.+40.),4.);
	} else if (mindex == 5) {
		em = vec3(0.);
		a = vec3(1.);
		r = .9;
		m = .0;
	} else {
		for (int i = 0; i < LN; ++i)
			if (mindex == 100 + i) {
				em = LC[i];
				a = vec3(0.);
				r = .0;
				m = .0;
			}
	}
	detail = false;
}

float DistributionGGX(float NH, float r) {
	r *= r; r *= r;
	float denom = NH * NH * (r - 1.) + 1.;
	denom = PI * denom * denom;
	return r / denom;
}
float GeometrySchlickGGX(float NV, float r) {
	r += 1.; r *= r / 8.;
	return NV / (NV * (1. - r) + r);
}
vec3 trace(vec3 o, vec3 d, float kw, float maxl) {
	float l = 0., minw = 1e3;
	int i;
	for (i = 0; i < 128; ++i) {
		vec3 p = o+d*l;
		float w = W(p);
		l += w * kw;
		minw = min(minw, w);
		if (w < .002*l || l > maxl) break;
	}
	return vec3(l, minw, float(i));
}
vec3 pbf(vec3 p, vec3 V, vec3 N, float ao, vec3 albedo, float metallic, float roughness) {
	vec3 Lo = vec3(0.);
	for(int i = 0; i < LN; ++i) {
    vec3 L = LP[i] - p; float LL = dot(L,L), Ls = sqrt(LL);
		L = normalize(L);

		vec3 tr = trace(p + .02 * L, L, 1., Ls);
		if (tr.y < .005 || tr.x < Ls ) continue;

    vec3 H = normalize(V + L);
		vec3 F0 = mix(vec3(.04), albedo, metallic);
		float HV = max(dot(H, V), .0), NV = max(dot(N, V), .0), NL = max(dot(N, L), 0.), NH = max(dot(N, H), 0.);
		vec3 F = F0 + (1. - F0) * pow(1. - HV, 5.);
		float G = GeometrySchlickGGX(NV, roughness) * GeometrySchlickGGX(NL, roughness);
		vec3 brdf = DistributionGGX(NH, roughness)* G * F / (4. * NV * NL + .001);
		Lo += ((vec3(1.) - F) * (1. - metallic)* albedo / PI + brdf) * NL * LC[i] / LL;
	}
	vec3 ambient = vec3(.03) * albedo * ao;
	return ambient + Lo;
}

mat3 lookat(vec3 p, vec3 a, vec3 y) {
	vec3 z = normalize(p - a);
	vec3 x = normalize(cross(y, z));
	y = cross(z, x);
	return mat3(x, y, z);
}

void main() {
	vec2 uv = gl_FragCoord.xy / V * 2. - 1.;
	uv.x *= V.x / V.y;
	
	float C = 11.;
	LP[0] = vec3(C, 6.,C);
	LP[1] = vec3(C, 6.,-C);
	LP[2] = vec3(-C, 6.,-C);
	LP[3] = vec3(-C, 6.,C);
	LP[4] = vec3(0.);

	LC[0] = 30.*vec3(.7,.35,.45)*mix(1.,noise(T*20.),.3);
	LC[1] = 30.*vec3(.7,.35,.15)*mix(1.,noise(T*20.+10.),.3);
	LC[2] = 30.*vec3(.3,.35,.75)*mix(1.,noise(T*20.+20.),.3);
	LC[3] = 30.*vec3(.7,.35,.15)*mix(1.,noise(T*20.+30.),.3);
	LC[4] = smoothstep(44., 50., T) * 50.*vec3(1.)*mix(1.,noise(T*20.+30.),.3);

	vec3 D = normalize(vec3(uv, -1.44));

	vec3 O, A = vec3(.0);
	if (T < 23.) {
		O = vec3(mix(40.,11.,T/23.), 2., 0.);
	} else if (T < 34.) {
		float t = T - 34.;
		O = vec3(cos(t*.1)*13., 2., sin(t*.1)*14.);
		A = vec3(20.,0.,20.);
	} else if (T < 62.) {
		O = vec3(cos(T*.1)*13., 2., sin(T*.1)*14.);
	} else {
		float t = T * 2. / 10.48;
		float tt = floor(t);
		O = 13.*mix(
			vec3(noise(tt), noise(tt+4.), noise(tt+5.)),
			vec3(noise(tt+17.), noise(tt+41.), noise(tt+35.)), t - tt);
	}
	float t = T * 3.;
	O += .1 * vec3(noise(t), noise(t+1.), noise(t+3.));
	mat3 LAT = lookat(O, A, E.xzx);
	O += LAT * vec3(uv*.01, 0.);
	D = LAT * D;

	vec3 color = vec3(0.);//E.zxz;
	
	const float maxl = 40.;
	vec3 tr = trace(O, D, 1., maxl);
	if (tr.x < maxl) {
		vec3 p = O + tr.x * D;
		vec3 albedo, em, n;
		float metallic, roughness;
		material(p, n, em, albedo, roughness, metallic);
		dlight = false;
		color = em + pbf(p, -D, n, 0. * pow(tr.z / 128., .5), albedo, metallic, roughness);
	}

	gl_FragColor = vec4(color, tr.x);
}
