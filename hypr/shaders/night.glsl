#version 320 es

/* Warm night shader adapted from @snes19xx/surface-dots. */

precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float WARMTH = 0.72;
const float DIMMING = 0.88;
const vec3 WARM_GAIN = vec3(1.06, 0.96, 0.52);

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    vec3 color = pixColor.rgb;
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    float warmthMask = pow(luma, 0.6);

    color = mix(color, color * WARM_GAIN, warmthMask * WARMTH);
    color *= DIMMING;

    fragColor = vec4(clamp(color, 0.0, 1.0), pixColor.a);
}
