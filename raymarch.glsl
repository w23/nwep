#version 130
uniform float T;
uniform vec2 V;
uniform vec3 M;

const vec3 E = vec3(.0,1e-3,1.);
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

float box(vec3 p, vec3 s) { p = abs(p) - s; return max(p.x, max(p.y, p.z)); }
mat3 RX(float a){ float s=sin(a),c=cos(a); return mat3(1.,0.,0.,0.,c,-s,0.,s,c); }
mat3 RY(float a){	float s=sin(a),c=cos(a); return mat3(c,0.,s,0.,1.,0,-s,0.,c); }
mat3 RZ(float a){ float s=sin(a),c=cos(a); return mat3(c,s,0.,-s,c,0.,0.,0.,1.); }

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
float hole(vec3 p) { return box(p-vec3(33.,1.6,0.), vec3(20.,1.5,1.96)); }
float room(vec3 p) {
	float holes = -min(hole(vec3(abs(p.x), p.yz)), hole(vec3(abs(p.z), p.yx)));;
	float plates = max(-ball(p,19.), box(rep(p, vec3(2.)), vec3(.8)));
	float extwall = -ball(p,20.);
	float wall = max(holes, min(extwall, plates));

	float rings = ball(p,9.);
	rings = max(rings, abs(abs(p.y)-3.)-.5);
	rings = min(rings, box(rep(p,vec3(11.8)), vec3(.1, 100., .1)));
	rings = max(rings, -ball(p,8.9));
	float paths = path(vec3(length(p.xz)-13., p.y, atan(p.x, p.z)*10.));
	paths = min(paths, max(15.-length(p.xz), min(path(p.zyx), path(p))));
	paths = max(paths, holes);

	float scene = wall;
	scene = min(scene, rings);
	scene = min(scene, paths);
	return scene;
}

#define LN 3
vec3 LP[3], LC[3];

float lights(vec3 p) {
	float d = 1e5;
	for (int i = 0; i < LN; ++i)
		d = min(d, length(p - LP[i]) - .1);
	return d;
}

bool dlight = true;

float W(vec3 p) {
	float kifs = F4(p/4.);
	float room = room(p);
	if (dlight) room = min(room, lights(p));
	return min(kifs, room);
}

vec3 N(vec3 p) {
	float w=W(p);
	return normalize(vec3(W(p+E.yxx)-w,W(p+E.xyx)-w,W(p+E.xxy)-w));
}

void material(vec3 p, out vec3 n, out vec3 em, out vec3 albedo, out float roughness, out float metallic) {
	n = N(p);

	em = vec3(0.);

	float droom = room(p);
	float dkifs = F4(p/4.);
	if (dkifs < droom) {
		albedo = vec3(1.);
		roughness = 1.;
		metallic = 0.;
	} else {
		albedo = vec3(.56, .57, .58);
		metallic = .8;
		roughness = .2;
		//pow(noise(p*4.),4.),
		roughness = .2 + .6 * pow(noise(p*4.+40.),4.);
	}
}

vec3 fresnelSchlick(float cosTheta, vec3 F0) { return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0); }
float DistributionGGX(vec3 N, vec3 H, float r) {
	float a      = r * r; a *= a;
	float NdotH  = max(dot(N, H), 0.0);
	float denom = NdotH * NdotH * (a - 1.0) + 1.0;
	denom = PI * denom * denom;
	return a / denom;
}
float GeometrySchlickGGX(float NdotV, float roughness) {
	float r = (roughness + 1.0);
	float k = (r*r) / 8.0;
	float nom   = NdotV;
	float denom = NdotV * (1.0 - k) + k;
	return nom / denom;
}
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness) {
	float NdotV = max(dot(N, V), 0.0);
	float NdotL = max(dot(N, L), 0.0);
	float ggx2  = GeometrySchlickGGX(NdotV, roughness);
	float ggx1  = GeometrySchlickGGX(NdotL, roughness);
	return ggx1 * ggx2;
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
	vec3 Lo = vec3(0.0);
	for(int i = 0; i < LN; ++i) {
    vec3 L = LP[i] - p; float LL = dot(L,L), Ls = sqrt(LL);
		L = normalize(L);

		vec3 tr = trace(p + .02 * L, L, 1., Ls);
		if (tr.y < .005 || tr.x < Ls ) continue;

    vec3 H = normalize(V + L);
    vec3 radiance = LC[i] / LL;
		vec3 F0 = mix(vec3(0.04), albedo, metallic);
		vec3 F  = fresnelSchlick(max(dot(H, V), 0.0), F0);
		float NDF = DistributionGGX(N, H, roughness);
		float G   = GeometrySmith(N, V, L, roughness);
		vec3 nominator    = NDF * G * F;
		float denominator = 4 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.001;
		vec3 brdf         = nominator / denominator;
		vec3 kS = F;
		vec3 kD = vec3(1.0) - kS;
		kD *= 1.0 - metallic;
		float NdotL = max(dot(N, L), 0.0);
		Lo += (kD * albedo / PI + brdf) * radiance * NdotL;
	}
	vec3 ambient = vec3(0.03) * albedo * ao;
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

	LP[0] = vec3(5.*sin(T), 5., 5.*cos(T));
	LP[1] = vec3(5.*sin(-T+3.), 5., 5.*cos(T+3.));
	LP[2] = vec3(0., 9.*sin(T*.7), 0.);
	LC[0] = 4.*vec3(10.);
	LC[1] = 4.*vec3(9.,10.,5.);
	LC[2] = 20.*vec3(14.,7.,3.);

	mat3 ML = RY(M.x*2e-3) * RX(M.y*2e-3);
	vec3 O = ML * vec3(0., 0., max(.1, M.z/10.));
	vec3 D = normalize(vec3(uv, -1.44));
	mat3 LAT = lookat(O, LP[0], E.xzx);
	O += LAT * vec3(uv, 0.);
	D = LAT * D;

	vec3 color = E.zxz;
	
	const float maxl = 40.;
	vec3 tr = trace(O, D, 1., maxl);
	if (tr.x < maxl) {
		dlight = false;
		vec3 p = O + tr.x * D;
		vec3 albedo, em, n;
		float metallic, roughness;
		material(p, n, em, albedo, roughness, metallic);
		color = em + pbf(p, -D, n, 0. * pow(tr.z / 128., .5), albedo, metallic, roughness);
	}

	gl_FragColor = vec4(color, tr.x);
}
