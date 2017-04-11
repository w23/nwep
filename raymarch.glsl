#version 130
uniform float T;
uniform vec2 V;
const vec3 E = vec3(.0,.001,1.);
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
float VR = 2.;//.2 + (sin(T*.1) + 1.) * 4.;

float F2(vec3 p) {
	p *= 2.;
	p = RY(T*.1) * p;
	float S = 1.2;
	const int N = 1;
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

float W(vec3 p) {
	return F4(p);
/*
	return min(p.y + 1.,
		min(length(p) - 1.,
			min(length(p-2.*E.zxx) - .8,
				length(p+2.*E.zxx) - .9)));
				*/
}

vec3 N(vec3 p) {
	float w=W(p);
	return normalize(vec3(W(p+E.yxx)-w,W(p+E.xyx)-w,W(p+E.xxy)-w));
}

void M(vec3 p, out vec3 albedo, out float roughness) {
	if (p.y < -.9) albedo = vec3(1.); else {
		if (p.x < -.9) albedo = vec3(1.,0.,0.); else
		if (p.x > .9) albedo = vec3(0.,0.,1.); else
		albedo = vec3(0.,1.,0.);
	}
	roughness = 1.;
	//roughness = min(1.,.1+pow(noise(p*3.), 4.));
}

const float ML = 50.;
vec3 LP[2], LC[2];
vec3 trace(vec3 o, vec3 d) {
	vec3 p,n;
	float l = 0.;
	for (int i = 0; i < 164; ++i) {
		p = o+d*l;
		float w = W(p);
		l += w;
		if (w < .001*l || l > ML) break;
	}

	if (l > ML) return vec3(1.);

	vec3 albedo = vec3(1.);
	n = N(p);
	d = -d;

#if 0
	p += n * .01;
	vec3 c = vec3(0.);
	for(int i = 0; i < 2; ++i) {
		vec3 L = LP[i] - p;
		float shadow = 1.;
		/*for (int j = 0; j < 8; ++j) {
			float w=W(p + L * float(j+1) / 8.);
			shadow = min(shadow, w);
		}
		if (shadow < .01) break;
		*/

		float dL = max(0.,dot(n,normalize(L)));
		c += dL * albedo * LC[i] / dot(L,L);
	}
#endif

	vec3 c = vec3(.05) + .95 * max(0., dot(n,normalize(vec3(1.))));

	return c;
}

void main() {
	vec2 uv = gl_FragCoord.xy / V * 2. - 1.;
	uv.x *= V.x / V.y;

	LP[0] = vec3(5.*sin(T), 5., 5.*cos(T));
	LP[1] = vec3(5.*sin(-T+3.), 5., 5.*cos(T+3.));
	LC[0] = vec3(10.);
	LC[1] = vec3(9.,10.,5.);

	vec3 O = vec3(0., 0., VR);
	vec3 D = normalize(vec3(uv, -2.));

	vec3 color = trace(O, D);

	color = color / (color + vec3(1.0));
	color = pow(color, vec3(1.0/2.2));

	gl_FragColor = vec4(color, 1.);
	//gl_FragColor = vec4(sin(T*10.));
}
