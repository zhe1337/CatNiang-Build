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

float cloudNoise(vec2 p, float t) {
    float n = 0.0;
    n += 0.50 * noise(p * 1.0 + vec2(t * 0.02, 0.0));
    n += 0.25 * noise(p * 2.0 + vec2(t * 0.03, 0.0));
    n += 0.125 * noise(p * 4.0 + vec2(t * 0.04, 0.0));
    return n / 0.875;
}

void main() {
    vec4 centerCol = texture(DiffuseSampler, texCoord);

    float t = time * 0.2;

    // 天空渐变 — 用texCoord.y
    vec3 topColor = vec3(0.1, 0.1, 0.35);
    vec3 midColor = vec3(0.8, 0.4, 0.2);
    vec3 horizonColor = vec3(1.0, 0.7, 0.3);

    float grad = texCoord.y;
    vec3 sky = mix(horizonColor, midColor, smoothstep(0.0, 0.4, grad));
    sky = mix(sky, topColor, smoothstep(0.4, 1.0, grad));

    // 太阳
    vec2 sunPos = vec2(0.5 + sin(t * 0.1) * 0.15, 0.2 + sin(t * 0.05) * 0.05);
    float sunDist = length(texCoord - sunPos);
    sky += smoothstep(0.1, 0.0, sunDist) * vec3(1.0, 0.9, 0.5);
    sky += smoothstep(0.35, 0.0, sunDist) * vec3(1.0, 0.5, 0.2) * 0.4;

    // 云层
    vec2 cloudUV = texCoord * vec2(3.0, 1.0);
    float cloud = cloudNoise(cloudUV, t);
    cloud = smoothstep(0.3, 0.7, cloud);
    cloud *= smoothstep(0.1, 0.35, texCoord.y) * smoothstep(0.8, 0.4, texCoord.y);

    vec3 cloudCol = mix(vec3(0.3, 0.2, 0.3), vec3(1.0, 0.6, 0.3),
                        smoothstep(0.3, 0.0, length(texCoord - sunPos)));
    sky = mix(sky, cloudCol, cloud * 0.6);

    // 光线
    vec2 rayDir = texCoord - sunPos;
    float rayAngle = atan(rayDir.y, rayDir.x);
    float rays = sin(rayAngle * 12.0 + t) * 0.5 + 0.5;
    rays *= smoothstep(0.5, 0.1, sunDist) * smoothstep(0.0, 0.05, sunDist);
    sky += rays * vec3(1.0, 0.8, 0.4) * 0.15;

    vec3 finalColor = clamp(sky * color, 0.0, 1.0);

    if (centerCol.a != 0.0) {
        fragColor = vec4(finalColor, mixFactor);
    } else {
        float alpha = glowShader();
        fragColor = vec4(finalColor, alpha);
    }
}