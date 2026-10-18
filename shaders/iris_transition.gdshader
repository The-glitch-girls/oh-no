shader_type canvas_item;

uniform float iris_radius : hint_range(0.0, 1.2) = 1.2;
uniform float edge_softness : hint_range(0.001, 0.05) = 0.012;

void fragment() {
	float aspect_ratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 centered_uv = (UV - vec2(0.5)) * vec2(aspect_ratio, 1.0);
	float distance_from_center = length(centered_uv);
	float black_alpha = 1.0;
	if (iris_radius > 0.0) {
		black_alpha = smoothstep(
			iris_radius - edge_softness,
			iris_radius + edge_softness,
			distance_from_center
		);
	}

	COLOR = vec4(0.0, 0.0, 0.0, black_alpha);
}
