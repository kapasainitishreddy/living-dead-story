// Ported from Sakura Crossing src/core/post.js (MIT): INK_SHADER (second
// difference of linear depth -> convex/concave ink, faded into the haze with
// distance, ink keeps 22 % of the underlying hue) followed by GRADE_SHADER
// (violet-shadow / paper-white split tone, warmth, lift, saturation 1.12,
// vignette). Drawn as a full-screen quad after the opaque pass.
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 ink_color : source_color = vec3(0.224, 0.196, 0.310);
uniform float thickness = 1.35;
uniform float sens = 0.0042;
uniform float concave_t = 0.026;
uniform float concave_amount = 0.42;
uniform float fade_start = 22.0;
uniform float fade_end = 60.0;
uniform float strength = 1.0;
uniform vec3 shadow_tint : source_color = vec3(0.678, 0.659, 0.816); // 0xada8d0
uniform vec3 light_tint : source_color = vec3(1.0, 0.969, 0.910);    // 0xfff7e8
uniform float saturation = 1.12;
uniform float lift = 0.032;
uniform float vignette = 0.15;
uniform float warmth = 0.05;
uniform float grade_amount = 1.0;
void vertex() { POSITION = vec4(VERTEX.xy, 0.0, 1.0); }
float lin_depth(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec4 ndc = vec4(uv * 2.0 - 1.0, d * 2.0 - 1.0, 1.0);
#else
	vec4 ndc = vec4(uv * 2.0 - 1.0, d, 1.0);
#endif
	vec4 v = inv_proj * ndc;
	return -v.z / v.w;
}
vec3 to_lin(vec3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c)); }
vec3 to_srgb(vec3 c) { return mix(c * 12.92, 1.055 * pow(max(c, vec3(0.0031308)), vec3(1.0 / 2.4)) - 0.055, step(0.0031308, c)); }
void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = texture(screen_tex, uv).rgb;
	vec2 t = thickness / VIEWPORT_SIZE;
	float dc = lin_depth(uv, INV_PROJECTION_MATRIX);
	float edge = 0.0;
	if (dc < 300.0) {
		float dl = lin_depth(uv - vec2(t.x, 0.0), INV_PROJECTION_MATRIX);
		float dr = lin_depth(uv + vec2(t.x, 0.0), INV_PROJECTION_MATRIX);
		float du = lin_depth(uv + vec2(0.0, t.y), INV_PROJECTION_MATRIX);
		float dd = lin_depth(uv - vec2(0.0, t.y), INV_PROJECTION_MATRIX);
		float sx = (dl + dr - 2.0 * dc) / dc;
		float sy = (du + dd - 2.0 * dc) / dc;
		float convex = max(0.0, sx) + max(0.0, sy);
		float concave = max(0.0, -sx) + max(0.0, -sy);
		edge = smoothstep(sens * 0.32, sens, convex);
		edge = max(edge, smoothstep(concave_t, concave_t * 3.4, concave) * concave_amount);
		edge *= 1.0 - smoothstep(fade_start, fade_end, dc);
		edge *= strength;
	}
	vec3 line = mix(ink_color, col * 0.42, 0.22);
	col = mix(col, line, clamp(edge, 0.0, 1.0));
	// grade, done in linear like the original
	vec3 c = to_lin(col);
	float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
	float k = smoothstep(0.02, 0.55, l);
	c *= mix(to_lin(shadow_tint), to_lin(light_tint), k);
	c += vec3(warmth, warmth * 0.45, 0.0) * l * 0.35;
	c += lift * (1.0 - k);
	c = mix(vec3(l), c, saturation);
	float r = length(uv - 0.5) * 1.42;
	c *= 1.0 - vignette * pow(clamp(r, 0.0, 1.0), 2.6);
	ALBEDO = mix(col, to_srgb(max(c, vec3(0.0))), grade_amount);
}
