shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, fog_disabled;
uniform vec3 ink_color : source_color = vec3(0.19, 0.20, 0.28);
uniform float ink_pixels = 0.75;
void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 view_normal = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
	vec2 projected = (PROJECTION_MATRIX * vec4(view_normal, 0.0)).xy;
	vec2 direction = projected / max(length(projected), 0.0001);
	clip.xy += direction * (2.0 * ink_pixels / VIEWPORT_SIZE) * clip.w;
	clip.z += 0.00002 * clip.w;
	POSITION = clip;
}
void fragment() { ALBEDO = ink_color; }
