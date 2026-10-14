// Petal card from Sakura Crossing src/core/textures.js petalTex (MIT): one
// rounded petal, wider at the tip with a small notch, flat-coloured (unlit,
// like `flat()`), alpha-tested at 0.32 and double sided.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.y = -p.y;
	float w = 0.78 * (1.0 - pow(abs(p.y * 0.95 - 0.12), 2.0));
	float body = smoothstep(0.02, -0.02, abs(p.x) - w * (p.y > -0.85 ? 1.0 : 0.0));
	float notch = 1.0 - smoothstep(0.12, 0.2, length(vec2(p.x * 1.6, p.y - 0.95)));
	ALBEDO = COLOR.rgb;
	ALPHA = body * (1.0 - notch) * 0.95;
	ALPHA_SCISSOR_THRESHOLD = 0.32;
}
