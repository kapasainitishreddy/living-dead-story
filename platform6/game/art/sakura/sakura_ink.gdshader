// Inverted-hull ink line (Sakura Crossing's outline.js approach, MIT).
shader_type spatial;
render_mode unshaded, cull_front, specular_disabled;
uniform vec4 ink : source_color = vec4(0.224, 0.196, 0.31, 1.0);
uniform float thickness = 0.008;
void vertex() { VERTEX += normalize(NORMAL) * thickness; }
void fragment() { ALBEDO = ink.rgb; }
