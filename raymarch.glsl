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

float W(vec3 p) {
	return min(p.y + 1.,
		min(length(p) - 1., min(length(p-2.*E.zxx) - .8,
			length(p+2.*E.zxx) - .9)));
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

const float ML = 10.;
vec3 LP[2], LC[2];

bool raytrace(vec3 o, vec3 d, out vec3 p, out vec3 n, out vec3 c, out vec3 albedo, out float roughness) {
	float l = 0.;
	for (int i = 0; i < 64; ++i) {
		p = o+d*l;
		float w = W(p);
		l += w;
		if (w < .001*l || l > ML) break;
	}
	c = vec3(0.);

	if (l > ML) return false;

	n = N(p);
	M(p, albedo, roughness);
	d = -d;

	p += n * .01;
	for(int i = 0; i < 2; ++i) {
		vec3 L = LP[i] - p;
		float shadow = 1.;
		for (int j = 0; j < 8; ++j) {
			float w=W(p + L * float(j+1) / 8.);
			shadow = min(shadow, w);
		}

		if (shadow < .0001) break;

		float dL = max(0.,dot(n,normalize(L)));
		c += dL * albedo * LC[i] / dot(L,L);
	}

	return true;
}

void main() {
	vec2 uv = gl_FragCoord.xy / V * 2. - 1.;
	uv.x *= V.x / V.y;

	LP[0] = vec3(5.*sin(T), 5., 5.*cos(T));
	LP[1] = vec3(5.*sin(T+3.), 5., -5.*cos(T));
	LC[0] = vec3(10.);
	LC[1] = vec3(9.,10.,5.);

	vec3 O = vec3(0., 0., 4.);
	vec3 D = normalize(vec3(uv, -2.));

	vec3 color,p,n,albedo;
	float r;
	raytrace(O, D, p, n, color, albedo, r);

	//r = 1.;
	float sum = 0.;
	vec3 col = vec3(0.);
	const int SAMPLE_COUNT = 1;
	vec3 nr = reflect(D,n);
	for (int j = 0; j < SAMPLE_COUNT; ++j) {
		float fj = float(j)+T;
		float rx = r * (hash(vec2(p.x, fj)) * 2. - 1.);
		float ry = r * (hash(vec2(p.y, fj)) * 2. - 1.);
		float rz = sqrt(1. - rx*rx - ry*ry);

		vec3 tg = abs(nr.z) > .9 ? E.zxx : E.xxz, btg = normalize(cross(nr,tg));
		tg = cross(btg,nr);
		vec3 dd = nr * rz + tg * rx + btg * ry;
		float k = max(0.,dot(dd,n));

		vec3 p2,n2,c2,a2;
		float r2;
		if (k > 0. && raytrace(p, dd, p2, n2, c2, a2, r2)) {
			col += c2;// * k;
			sum += 1.;
		}
	}

	if (sum > 0.)
		color += col * albedo / sum;
	//color = col;

	color = color / (color + vec3(1.0));
	color = pow(color, vec3(1.0/2.2));

	gl_FragColor = vec4(color, 1.);
	//gl_FragColor = vec4(sin(T*10.));
}
