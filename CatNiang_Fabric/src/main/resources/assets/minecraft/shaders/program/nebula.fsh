#version 150

uniform sampler2D DiffuseSampler;
in vec2 texCoord;
out vec4 fragColor;

uniform vec2 resolution;
uniform vec3 color;
uniform float mixFactor;
uniform float minAlpha;
uniform float quality;
uniform float radius;
uniform float divider;
uniform float maxSample;
uniform float time;

float glowShader() {
    vec2 texelSize = vec2(1.0 / resolution.x * (radius * quality), 1.0 / resolution.y * (radius * quality));
    float alpha = 0.0;
    for (float x = -radius; x < radius; x++) {
        for (float y = -radius; y < radius; y++) {
            vec4 currentColor = texture(DiffuseSampler, texCoord + vec2(texelSize.x * x, texelSize.y * y));
            if (currentColor.a != 0.0)
                alpha += divider > 0.0 ? max(0.0, (maxSample - distance(vec2(x, y), vec2(0.0))) / divider) : 1.0;
            alpha *= minAlpha;
        }
    }
    return alpha;
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
        f.y
    );
}

float nebulaNoise(vec2 p, float t) {
    float f = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++) {
        f += amp * noise(p + t * 0.05 * float(i + 1));
        amp *= 0.5;
        p = mat2(0.8, 0.6, -0.6, 0.8) * p * 2.0;
    }
    return f;
}

vec3 nebulaColor(float n, float t) {
    vec3 c1 = vec3(0.5, 0.0, 0.8);
    vec3 c2 = vec3(0.0, 0.3, 0.8);
    vec3 c3 = vec3(0.8, 0.2, 0.3);
    vec3 c4 = vec3(0.1, 0.6, 0.5);
    float phase = t * 0.1;
    vec3 col = mix(c1, c2, smoothstep(0.0, 0.33, n + sin(phase) * 0.1));
    col = mix(col, c3, smoothstep(0.33, 0.66, n + cos(phase) * 0.1));
    col = mix(col, c4, smoothstep(0.66, 1.0, n));
    return col;
}

void main() {
    vec4 centerCol = texture(DiffuseSampler, texCoord);

    vec2 uv = texCoord - 0.5;
    uv.x *= resolution.x / resolution.y;
    float t = time * 0.3;

    float angle = t * 0.02;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 ruv = rot * uv;

    float n1 = nebulaNoise(ruv * 2.0, t);
    float n2 = nebulaNoise(ruv * 3.0 + 100.0, t * 0.7);
    float n3 = nebulaNoise(ruv * 1.5 - 50.0, t * 0.5);

    float nebula = n1 * 0.5 + n2 * 0.3 + n3 * 0.2;
    nebula = smoothstep(0.2, 0.8, nebula);

    vec3 col = nebulaColor(nebula, t) * nebula;
    col += vec3(0.01, 0.0, 0.02);

    // 星星
    vec2 starGrid = floor(texCoord * 60.0);
    float star = hash(starGrid);
    if (star > 0.97) {
        float twinkle = 0.7 + 0.3 * sin(t * 5.0 + star * 50.0);
        vec2 starPos = fract(texCoord * 60.0) - 0.5;
        col += smoothstep(0.1, 0.0, length(starPos)) * twinkle * vec3(1.0, 0.95, 0.9);
    }

    // 亮星
    vec2 brightGrid = floor(texCoord * 20.0);
    float brightStar = hash(brightGrid + 100.0);
    if (brightStar > 0.985) {
        vec2 sp = fract(texCoord * 20.0) - 0.5;
        col += exp(-length(sp) * 8.0) * vec3(0.6, 0.7, 1.0) * 0.5;
    }

    vec3 finalColor = clamp(col * color, 0.0, 1.0);

    if (centerCol.a != 0.0) {
        fragColor = vec4(finalColor, mixFactor);
    } else {
        float alpha = glowShader();
        fragColor = vec4(finalColor, alpha);
    }
}