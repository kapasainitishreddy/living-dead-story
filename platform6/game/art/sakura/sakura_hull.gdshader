// Ported from Sakura Crossing src/core/outline.js hullVert (MIT): a back-face
// shell pushed out along the clip-space normal, scaled by clip.w so the ink line
// is a constant screen width whatever the distance. Thicker than the original
// (which leans on a depth-edge post pass) so it reads on phones.
shader_type spatial;
render_mode unshaded, cull_front, specular_disabled, fog_disabled, shadows_disabled;
uniform vec4 ink : source_color = vec4(0.224, 0.196, 0.310, 1.0); // PAL.ink 0x39324f
uniform float thickness = 0.0052;
void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 n = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 cn = normalize((PROJECTION_MATRIX * vec4(n, 0.0)).xyz);
	vec2 aspect = vec2(VIEWPORT_SIZE.y / VIEWPORT_SIZE.x, 1.0);
	clip.xy += normalize(cn.xy + vec2(1e-5)) * aspect * thickness * clip.w;
	POSITION = clip;
}
void fragment() { ALBEDO = ink.rgb; }
