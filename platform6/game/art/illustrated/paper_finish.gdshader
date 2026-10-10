shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene_texture : hint_screen_texture, filter_linear;
uniform float paper_strength = 0.003;
uniform float warmth = 0.06;
void fragment() {
	vec3 original = texture(scene_texture, SCREEN_UV).rgb;
	float value = dot(original, vec3(0.2126, 0.7152, 0.0722));
	float shadow = 1.0 - smoothstep(0.10, 0.48, value);
	vec3 cool = original * vec3(0.94, 0.96, 1.06) + vec3(0.006, 0.004, 0.010);
	vec3 colour = mix(original, cool, shadow * 0.22);
	colour = mix(colour, colour * vec3(1.035, 1.012, 0.966), warmth);
	// Fixed paper grain: no temporal noise, camera shake or animation.
	vec2 pixel = floor(SCREEN_UV / SCREEN_PIXEL_SIZE);
	float grain = fract(sin(dot(pixel, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	COLOR = vec4(clamp(colour + grain * paper_strength, 0.0, 1.0), 1.0);
}
