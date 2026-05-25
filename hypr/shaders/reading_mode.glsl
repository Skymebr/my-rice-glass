#version 320 es

/*
   E-ink style reading shader adapted from @snes19xx/surface-dots.
   Source: https://github.com/snes19xx/surface-dots
*/

precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

float getBayer(vec2 pos) {
    int x = int(mod(pos.x, 4.0));
    int y = int(mod(pos.y, 4.0));
    const mat4 bayer = mat4(
        0.0, 12.0, 3.0, 15.0,
        8.0, 4.0, 11.0, 7.0,
        2.0, 14.0, 1.0, 13.0,
        10.0, 6.0, 9.0, 5.0
    );
    return bayer[x][y] / 16.0;
}

float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float paperTexture(vec2 uv) {
    float n = 0.0;
    n += hash(uv * 0.3) * 0.6;
    n += hash(uv * 0.8) * 0.4;
    n += hash(uv * 2.5) * 0.3;
    n += hash(uv * 6.0) * 0.2;
    n += hash(uv * 15.0) * 0.1;
    return n / 1.6;
}

float directionalGrain(vec2 uv) {
    vec2 direction = vec2(0.7, 0.3);
    float grain = 0.0;
    grain += hash(uv * 3.0 + direction * 2.0) * 0.5;
    grain += hash(uv * 8.0 + direction * 5.0) * 0.3;
    return grain / 0.8;
}

float vignette(vec2 uv) {
    vec2 center = uv - 0.5;
    float dist = length(center);
    return 1.0 - smoothstep(0.4, 1.2, dist) * 0.15;
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    float gray = dot(pixColor.rgb, vec3(0.299, 0.587, 0.114));

    gray = pow(gray, 1.2);
    gray = smoothstep(0.08, 0.92, gray);

    float midBoost = smoothstep(0.3, 0.5, gray) * (1.0 - smoothstep(0.5, 0.7, gray));
    gray += midBoost * 0.1;

    vec2 screenPos = gl_FragCoord.xy;
    float paperGrain = (paperTexture(screenPos * 0.3) - 0.5) * 0.035;
    float dirGrain = (directionalGrain(screenPos * 0.4) - 0.5) * 0.025;
    float bayerValue = getBayer(screenPos);
    float textureMask = smoothstep(0.5, 0.95, gray);

    gray += paperGrain * textureMask;
    gray += dirGrain * textureMask * 0.7;
    gray += (bayerValue - 0.5) * 0.025 * textureMask;
    gray *= vignette(v_texcoord);
    gray = clamp(gray, 0.0, 1.0);

    vec3 paperColor = vec3(0.94, 0.92, 0.86);
    vec3 inkColor = vec3(0.10, 0.10, 0.12);
    float colorVariation = hash(screenPos * 0.08) * 0.02;
    paperColor += vec3(colorVariation, colorVariation * 0.5, -colorVariation * 0.2);

    fragColor = vec4(mix(inkColor, paperColor, gray), pixColor.a);
}
