// Ported from Sakura Crossing src/core/toon.js (MIT, (c) 2026 Kenton Wang; see
// SAKURA_CROSSING_LICENSE.txt). MeshToonMaterial with a NearestFilter gradient
// ramp: RAMPS[3] = [92,178,255] sampled at dotNL*0.5+0.5, so the bands break at
// dotNL = +-1/3. The patched toon chunk tints each band toward `shadow_tint`
// (irradiance = band * mix(tint, 1, band)), which is what keeps shade violet
// instead of grey. HemisphereLight (hemiSky/hemiGround) is evaluated here too.
// flat=true reproduces three's flatShading facet look via screen derivatives.
shader_type spatial;
render_mode specular_disabled, ambient_light_disabled;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, hint_default_white;
uniform bool use_tex = false;
uniform vec3 shadow_tint : source_color = vec3(0.424, 0.373, 0.549); // 0x6c5f8c
uniform bool flat_shade = true;
uniform bool soft_ramp = false; // RAMPS.soft = [180,255] for blossom masses
uniform vec3 hemi_sky : source_color = vec3(0.863, 0.925, 1.0);   // PAL.hemiSky
uniform vec3 hemi_ground : source_color = vec3(0.714, 0.651, 0.776); // PAL.hemiGround
uniform float hemi_energy = 0.30;
uniform float light_scale = 1.0;
varying vec3 world_n;
void vertex() { world_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
float ramp(float ndl) {
	float u = ndl * 0.5 + 0.5;
	if (soft_ramp) return u < 0.5 ? 180.0 / 255.0 : 1.0;
	if (u < 1.0 / 3.0) return 92.0 / 255.0;
	if (u < 2.0 / 3.0) return 178.0 / 255.0;
	return 1.0;
}
void fragment() {
	vec3 c = albedo.rgb;
	if (use_tex) c *= texture(albedo_tex, UV).rgb;
	ALBEDO = c;
	ROUGHNESS = 1.0;
	if (flat_shade) {
		vec3 fn = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
		NORMAL = dot(fn, VIEW) < 0.0 ? -fn : fn; // derivative sign depends on screen y
	}
	vec3 wn = flat_shade ? (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz : normalize(world_n);
	vec3 hemi = mix(hemi_ground, hemi_sky, wn.y * 0.5 + 0.5);
	EMISSION = c * hemi * hemi_energy;
}
void light() {
	float band = ramp(dot(NORMAL, LIGHT));
	// ATTENUATION carries the shadow map: a shadowed texel drops to the lowest band.
	float lit = min(band, mix(92.0 / 255.0, 1.0, ATTENUATION));
	vec3 tint = mix(shadow_tint, vec3(1.0), lit);
	DIFFUSE_LIGHT += lit * tint * LIGHT_COLOR * light_scale / PI;
}
