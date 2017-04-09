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

float DistributionGGX(vec3 N, vec3 H, float roughness) {
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;
    float nom   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
    return nom / denom;
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
vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}
float RadicalInverse_VdC(uint bits) {
	bits = (bits << 16u) | (bits >> 16u);
	bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
	bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
	bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
	bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
	return float(bits) * 2.3283064365386963e-10; // / 0x100000000
}
vec2 Hammersley(uint i, uint N) {
	return vec2(float(i)/float(N), RadicalInverse_VdC(i));
}

vec3 ImportanceSampleGGX(vec2 Xi, vec3 N, float roughness) {
	float a = roughness*roughness;

	float phi = 2.0 * PI * Xi.x;
	float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a*a - 1.0) * Xi.y));
	float sinTheta = sqrt(1.0 - cosTheta*cosTheta);

	// from spherical coordinates to cartesian coordinates - halfway vector
	vec3 H;
	H.x = cos(phi) * sinTheta;
	H.y = sin(phi) * sinTheta;
	H.z = cosTheta;

	//from tangent-space H vector to world-space sample vector
	vec3 up        = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
	vec3 tangent   = normalize(cross(up, N));
	vec3 bitangent = cross(N, tangent);

	vec3 sampleVec = tangent * H.x + bitangent * H.y + N * H.z;
	return normalize(sampleVec);
}

void M(vec3 p, out vec3 albedo, out float metallic, out float roughness) {
	albedo = vec3(step(p.y,-.9), 1., 1.);
	metallic = .9;
	roughness = noise(p*3.);
}

const float ML = 10.;
vec3 LP[2], LC[2];

bool raytrace(vec3 o, vec3 d, out vec3 p, out vec3 n, out vec3 c, out vec3 albedo, out float metallic, out float roughness) {
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
	M(p, albedo, metallic, roughness);
	d = -d;

	for(int i = 0; i < 2; ++i)
	{
		vec3 L = normalize(LP[i] - p);
		float distance    = length(LP[i] - p);

		float shadow = 1.;
		for (int j = 0; j < 8; ++j) {
			float w=W(p + n * .01 + L * distance * float(j+1) / 8.);
			shadow = min(shadow, w);
		}

		if (shadow < .01) break;

		vec3 H = normalize(d + L);
		float attenuation = 1.0 / (distance * distance);
		vec3 radiance     = LC[i] * attenuation;
		vec3 F0 = mix(vec3(.04), albedo, metallic);
		vec3 F  = fresnelSchlick(max(dot(H, d), 0.0), F0);
		float NDF = DistributionGGX(n, H, roughness);
		float G   = GeometrySmith(n, d, L, roughness);
		float NdotL = max(dot(n, L), 0.0);
		vec3 nominator    = NDF * G * F;
		float denominator = 4. * max(dot(n, d), 0.0) * NdotL + 0.001;
		vec3 brdf         = nominator / denominator;

		vec3 kS = F;
		vec3 kD = vec3(1.0) - kS;
		kD *= 1.0 - metallic;
		c += (kD * albedo / PI + brdf) * radiance * NdotL;
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
	float m,r;
	raytrace(O, D, p, n, color, albedo, m, r);

	float sum = 0.;
	vec3 col = vec3(0.);
	const uint SAMPLE_COUNT = 6u;
	uint dj = uint(hash(p)*float(SAMPLE_COUNT));
	for (uint j = 0u; j < SAMPLE_COUNT; ++j) {
		vec2 Xi = Hammersley(j+dj, 2u*SAMPLE_COUNT);
		vec3 H  = ImportanceSampleGGX(Xi, n, r);
		vec3 L2  = normalize(2.*dot(-D, H)*H+D);
		float NdotL2 = max(dot(n, L2), 0.0);
		if(NdotL2 > 0.0)
		{
			vec3 p2,n2,c2,a2;
			float m2,r2;
			raytrace(p+n*.01, L2, p2, n2, c2, a2, m2, r2);
			col += c2 * NdotL2;
			sum += NdotL2;
		}
	}

	color += col * albedo / sum;
	//color = col;

	color = color / (color + vec3(1.0));
	color = pow(color, vec3(1.0/2.2));

	gl_FragColor = vec4(color, 1.);
	//gl_FragColor = vec4(sin(T*10.));
}
