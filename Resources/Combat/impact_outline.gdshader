// Impact frame prototype: black screen + thin white outlines of whatever was drawn.
// Assign this to a fullscreen ColorRect (CombatFx/ImpactRect) via ShaderMaterial.

shader_type canvas_item; // 2D/UI shader (ColorRect lives in canvas space)

// Grab the already-rendered game view so we can edge-detect it.
// hint_screen_texture = read the screen; filter_linear = smooth sampling.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

// How strong a color difference must be before we treat it as an "edge".
// Higher = fewer / thicker-looking lines (less sensitive).
uniform float threshold : hint_range(0.0, 1.0) = 0.15;

// Multiplies edge intensity before the threshold check.
// Higher = more lines show up.
uniform float line_strength : hint_range(0.5, 4.0) = 2.0;

void fragment() {
	// Size of one pixel in UV space (0–1), so neighbor samples are exactly 1px away.
	vec2 px = 1.0 / vec2(textureSize(screen_texture, 0));

	// Center pixel color (current screen UV).
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;

	// Samples one pixel left / right / up / down for a simple edge detect.
	vec3 l = texture(screen_texture, SCREEN_UV + vec2(-px.x, 0.0)).rgb;
	vec3 r = texture(screen_texture, SCREEN_UV + vec2(px.x, 0.0)).rgb;
	vec3 u = texture(screen_texture, SCREEN_UV + vec2(0.0, -px.y)).rgb;
	vec3 d = texture(screen_texture, SCREEN_UV + vec2(0.0, px.y)).rgb;

	// How different neighbors are from the center = edge amount.
	float edge = length(c - l) + length(c - r) + length(c - u) + length(c - d);

	// Boost, then hard-ish cut: below threshold → 0 (black), above → toward 1 (white line).
	edge = smoothstep(threshold, threshold + 0.05, edge * line_strength);

	// Output: RGB all set to edge (black bg, white outlines), fully opaque.
	COLOR = vec4(vec3(edge), 1.0);
}
