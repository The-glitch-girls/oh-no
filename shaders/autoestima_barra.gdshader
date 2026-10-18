shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.25;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    float aspect = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
    float width = aspect * clamp(progress, 0.0, 1.0);

    float radius = min(0.5, width * 0.5);

    vec2 p = vec2(UV.x * aspect, UV.y);
    vec2 half_size = vec2(width * 0.5, 0.5);
    vec2 q = abs(p - half_size) - (half_size - vec2(radius));

    float distance_to_edge =
        length(max(q, vec2(0.0))) +
        min(max(q.x, q.y), 0.0) -
        radius;

    float mask = 1.0 - smoothstep(
        -0.005,
         0.005,
         distance_to_edge
    );

    color.a *= mask;
    COLOR = color;
}