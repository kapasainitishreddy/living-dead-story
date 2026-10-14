// Ported from Sakura Crossing src/core/sky.js (MIT): the dome gradient
// (haze -> mid -> top with a faint 26-step painted quantisation and warmth low
// in the sky) and the flat cel clouds, here painted analytically instead of as
// billboards: each cloud is cloudTex's seven ellipse puffs with a flat bottom,
// cloud tone at 0.62 opacity over a cloudShade copy at 0.34.
shader_type sky;
uniform vec3 top : source_color = vec3(0.561, 0.741, 0.918);  // PAL.skyTop 0x8fbdea
uniform vec3 mid : source_color = vec3(0.831, 0.910, 0.980);  // PAL.skyMid 0xd4e8fa
uniform vec3 haze : source_color = vec3(0.984, 0.906, 0.914); // PAL.skyHaze 0xfbe7e9
uniform vec3 cloud : source_color = vec3(0.992, 0.980, 0.973);
uniform vec3 cloud_shade : source_color = vec3(0.902, 0.902, 0.949);
uniform float bands = 26.0;
float hash(float n) { return fract(sin(n * 12.9898) * 43758.5453); }
float puffs(vec2 p) {
	// cloudTex(): seven ellipses in a 2:1 card, bottom trimmed flat.
	const vec3 P[7] = vec3[](vec3(0.22,0.62,0.15), vec3(0.36,0.46,0.2), vec3(0.52,0.4,0.24),
		vec3(0.68,0.5,0.19), vec3(0.82,0.63,0.14), vec3(0.45,0.66,0.2), vec3(0.6,0.68,0.17));
	if (p.y > 0.72 || p.x < 0.0 || p.x > 1.0 || p.y < 0.0) return 0.0;
	float a = 0.0;
	for (int i = 0; i < 7; i++) {
		vec2 d = (p - P[i].xy) / vec2(P[i].z * 0.55, P[i].z * 1.1 * 0.5);
		a = max(a, 1.0 - smoothstep(0.92, 1.0, length(d)));
	}
	return a;
}
void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	float t = clamp(h * 1.15 + 0.02, 0.0, 1.0);
	float q = floor(t * bands) / bands;
	t = mix(t, q, 0.35);
	vec3 col = mix(haze, mid, smoothstep(0.0, 0.30, t));
	col = mix(col, top, smoothstep(0.26, 0.92, t));
	col = mix(col, haze, smoothstep(0.12, -0.05, h) * 0.6);
	float az = atan(d.z, d.x);
	float el = asin(clamp(h, -1.0, 1.0));
	for (int i = 0; i < 18; i++) {
		float fi = float(i);
		float caz = hash(fi + 1.3) * 6.2832 - 3.1416;
		float w = mix(0.42, 0.95, hash(fi + 7.1));      // angular width
		float cel_ = mix(0.10, 0.42, hash(fi + 3.7));   // elevation of card centre
		float hh = w * mix(0.24, 0.34, hash(fi + 9.2)) * 1.6;
		float dx = mod(az - caz + 3.1416, 6.2832) - 3.1416;
		vec2 uv = vec2(dx / w + 0.5, 1.0 - ((el - cel_) / hh + 0.5));
		float back = puffs(uv - vec2(0.012, -0.05));
		float front = puffs(uv);
		col = mix(col, cloud_shade, back * 0.34);
		col = mix(col, cloud, front * 0.62);
	}
	COLOR = col;
}
