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
uniform float u_ViewYaw;
uniform float u_ViewPitch;

// screen pixel dir -> fixed world-space view direction
vec3 skyDir(vec2 suv) {
    vec3 rdL = vec3(suv * 1.4, -1.0);
    float yaw = radians(u_ViewYaw);
    float pit = radians(u_ViewPitch);
    float cp = cos(pit);
    vec3 fwd = vec3(-sin(yaw) * cp, -sin(pit), cos(yaw) * cp);
    vec3 rgt = vec3(-cos(yaw), 0.0, -sin(yaw));
    vec3 upv = cross(rgt, fwd);
    return normalize(fwd + suv.x * 1.4 * rgt + suv.y * 1.4 * upv);
}

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
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float f = 0.0;
    f += 0.5000 * noise(p); p *= 2.02;
    f += 0.2500 * noise(p); p *= 2.03;
    f += 0.1250 * noise(p);
    return f / 0.875;
}

vec3 auroraEffect(vec2 uv, float t) {
    vec3 col = vec3(0.0);
    for (float i = 0.0; i < 3.0; i++) {
        float speed = 0.05 + i * 0.02;
        float baseY = -0.1 + i * 0.15;

        float y = uv.y - baseY + sin(uv.x * (2.0 + i) + t * speed) * 0.08;
        y += fbm(vec2(uv.x * 2.0 + t * 0.05, t * 0.1 + i)) * 0.12;

        float wave = smoothstep(-0.15, 0.0, y) * smoothstep(0.25, 0.05, y);
        wave *= 0.5 + 0.5 * sin(uv.x * 8.0 + t * 0.5 + i * 2.0);

        vec3 auroraCol = mix(
            vec3(0.1, 0.8, 0.4),
            vec3(0.2, 0.4, 0.9),
            sin(uv.x * 3.0 + t * 0.2 + i) * 0.5 + 0.5
        );
        auroraCol = mix(auroraCol, vec3(0.8, 0.2, 0.5), i * 0.2);
        col += wave * auroraCol * (0.7 - i * 0.15);
    }
    return col;
}

void main() {
    vec4 centerCol = texture(DiffuseSampler, texCoord);

    vec2 uv0 = texCoord - 0.5;
    uv0.x *= resolution.x / resolution.y;

    // world-fixed sampling: azimuth + elevation of the actual view ray
    vec3 rd = skyDir(uv0);
    vec2 wuv = vec2(atan(rd.x, rd.z), rd.y);
    vec2 uv = wuv * vec2(2.0, 1.5);
    float t = time * 0.5;

    // 深空背景
    vec3 bg = mix(vec3(0.0, 0.0, 0.03), vec3(0.02, 0.0, 0.06), clamp(rd.y * 0.5 + 0.5, 0.0, 1.0));

    // 星星
    vec2 starUV = floor(wuv * vec2(16.0, 10.0));
    float star = hash(starUV);
    star = step(0.98, star) * (0.5 + 0.5 * sin(t * 3.0 + star * 100.0));
    bg += star * 0.6;

    // 极光
    bg += auroraEffect(uv, t);

    vec3 finalColor = clamp(bg * color, 0.0, 1.0);

    if (centerCol.a != 0.0) {
        fragColor = vec4(finalColor, mixFactor);
    } else {
        float alpha = glowShader();
        fragColor = vec4(finalColor, alpha);
    }
}
