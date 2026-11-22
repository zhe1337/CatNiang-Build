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
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec4 centerCol = texture(DiffuseSampler, texCoord);

    vec2 uv = texCoord - 0.5;
    uv.x *= resolution.x / resolution.y;
    float t = time * 0.5;

    // 渐变背景
    vec3 col = mix(vec3(0.1, 0.05, 0.2), vec3(0.05, 0.05, 0.15), texCoord.y);

    // 5层波浪
    for (float i = 0.0; i < 5.0; i++) {
        float layer = i / 5.0;
        float baseY = -0.3 + layer * 0.15;

        float w = sin(uv.x * (3.0 + i) + t * (0.5 + i * 0.1)) * 0.05;
        w += sin(uv.x * (5.0 + i * 2.0) + t * (0.7 + i * 0.15)) * 0.03;
        w += sin(uv.x * (8.0 + i * 3.0) + t * (1.0 + i * 0.2)) * 0.02;

        float waveY = baseY + w;
        float waveDist = abs(uv.y - waveY);
        float waveIntensity = smoothstep(0.02, 0.0, waveDist);

        vec3 waveColor = mix(vec3(0.2, 0.5, 0.9), vec3(0.6, 0.2, 0.8), layer);
        waveColor = mix(waveColor, vec3(0.9, 0.4, 0.6), sin(t * 0.3 + layer * 3.0) * 0.5 + 0.5);

        float glow = smoothstep(0.1, 0.0, waveDist) * 0.3;
        col += waveIntensity * waveColor * (1.0 - layer * 0.3);
        col += glow * waveColor * 0.4;
    }

    // 粒子
    vec2 particleUV = texCoord * vec2(20.0, 10.0);
    vec2 particleID = floor(particleUV);
    vec2 particlePos = fract(particleUV) - 0.5;
    float pHash = hash(particleID);
    if (pHash > 0.85) {
        particlePos.y -= sin(t * (1.0 + pHash) + pHash * 10.0) * 0.3;
        float particle = smoothstep(0.15, 0.0, length(particlePos));
        particle *= 0.5 + 0.5 * sin(t * 3.0 + pHash * 20.0);
        col += particle * vec3(0.8, 0.9, 1.0) * 0.4;
    }

    vec3 finalColor = clamp(col * color, 0.0, 1.0);

    if (centerCol.a != 0.0) {
        fragColor = vec4(finalColor, mixFactor);
    } else {
        float alpha = glowShader();
        fragColor = vec4(finalColor, alpha);
    }
}