shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D surface_atlas : source_color, filter_linear, repeat_disable;
uniform vec4 atlas_region = vec4(0.0, 0.0, 0.25, 0.5);
uniform float mark_strength : hint_range(0.0, 1.0) = 0.22;
uniform vec3 shadow_tint : source_color = vec3(0.53, 0.49, 0.72);
uniform vec3 highlight_tint : source_color = vec3(1.0, 0.91, 0.75);
void fragment() {
	vec2 atlas_uv = atlas_region.xy + clamp(UV, vec2(0.008), vec2(0.992)) * atlas_region.zw;
	vec3 painted = texture(surface_atlas, atlas_uv).rgb;
	ALBEDO = base_color.rgb * mix(vec3(1.0), painted, mark_strength);
	ROUGHNESS = 0.94;
	// A single shadow floor per fragment, never multiplied by local lamp count.
	EMISSION = ALBEDO * shadow_tint * 0.10;
}
void light() {
	float incidence = max(dot(NORMAL, LIGHT), 0.0);
	float energy = incidence * ATTENUATION;
	float middle = smoothstep(0.17, 0.23, energy);
	float high = smoothstep(0.61, 0.68, energy);
	vec3 hue = mix(shadow_tint, vec3(0.83, 0.85, 0.94), middle);
	hue = mix(hue, highlight_tint, high);
	float band = mix(0.0, 0.49, middle);
	band = mix(band, 0.87, high);
	DIFFUSE_LIGHT += hue * band * LIGHT_COLOR / 3.14159265;
}
