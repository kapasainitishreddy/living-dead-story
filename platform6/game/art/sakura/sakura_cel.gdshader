// Cel material for the Sakura animation pass. Technique adapted from
// Sakura Crossing (MIT, (c) 2026 Kenton Wang; see SAKURA_CROSSING_LICENSE.txt):
// quantised key light in 3 soft bands, with the shadow bands tinted toward a
// cool violet instead of simply darkening, plus a gentle rim.
shader_type spatial;
render_mode specular_disabled;
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec3 shadow_tint : source_color = vec3(0.47, 0.42, 0.62);
uniform float rim_strength = 0.18;
void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = albedo.rgb * rim * rim_strength;
}
void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = mix(0.38, 0.68, smoothstep(-0.12, -0.04, ndl));
	band = mix(band, 1.0, smoothstep(0.30, 0.38, ndl));
	vec3 tint = mix(shadow_tint, vec3(1.0), band);
	DIFFUSE_LIGHT += band * tint * ATTENUATION * LIGHT_COLOR / PI;
}
