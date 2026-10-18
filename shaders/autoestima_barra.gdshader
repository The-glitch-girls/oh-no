shader_type canvas_item;

uniform float progreso : hint_range(0.0, 1.0) = 0.5;
uniform float radio : hint_range(0.0, 0.5) = 0.5;

void fragment() {
    vec4 color = texture(TEXTURE, UV) * COLOR;

    // Radio de la cápsula en coordenadas UV.
    float r = min(radio, 0.5);

    // La posición del extremo sigue el progreso.
    float extremo = clamp(progreso, 0.0, 1.0);

    // Distancia al borde redondeado del extremo derecho.
    float centro_x = extremo - r;
    float centro_y = 0.5;

    float dx = max(abs(UV.x - centro_x) - (extremo > r ? extremo - r : 0.0), 0.0);
    float dy = abs(UV.y - centro_y) - (0.5 - r);

    float distancia = length(vec2(dx, dy)) - r;

    // Máscara antialias para bordes suaves.
    float mascara = 1.0 - smoothstep(
        -fwidth(distancia),
        fwidth(distancia),
        distancia
    );

    // Ocultar todo lo que queda a la derecha del extremo.
    float visible = step(UV.x, extremo);

    COLOR = vec4(
        color.rgb,
        color.a * mascara * visible
    );
}