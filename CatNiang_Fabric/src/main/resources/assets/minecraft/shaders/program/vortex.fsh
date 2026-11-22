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

#define PI 3.14159265

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

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    vec4 centerCol = texture(DiffuseSampler, texCoord);

    vec2 uv = texCoord - 0.5;
    uv.x *= resolution.x / resolution.y;
    float t = time * 0.3;

    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    float twist = 3.0 / (dist + 0.3);
    angle += twist * 0.5 + t * 0.2;

    vec3 col = vec3(0.02, 0.01, 0.05);

    // 2条旋臂
    for (float i = 0.0; i < 2.0; i++) {
        float armAngle = angle + i * PI;
        float arm = sin(armAngle * 2.0 - dist * 8.0 + t);
        arm = smoothstep(0.0, 1.0, arm);
        arm *= smoothstep(2.0, 0.0, dist) * smoothstep(0.0, 0.15, dist);

        vec3 armColor = mix(vec3(0.2, 0.3, 0.8), vec3(0.8, 0.3, 0.6), dist * 0.8);
        col += arm * armColor * 0.4;
    }

    // 核心
    col += exp(-dist * 4.0) * vec3(1.0, 0.9, 0.7) * 0.8;

    // 极坐标星星
    vec2 polarUV = vec2(fract(angle / PI * 0.5 + 0.5 + t * 0.02), dist);
    vec2 starGrid = floor(polarUV * vec2(30.0, 20.0));
    float starVal = hash2(starGrid);
    if (starVal > 0.92) {
        vec2 starPos = fract(polarUV * vec2(30.0, 20.0)) - 0.5;
        float starBright = smoothstep(0.15, 0.0, length(starPos));
        starBright *= 0.6 + 0.4 * sin(t * 4.0 + starVal * 20.0);
        starBright *= smoothstep(0.0, 0.3, dist);
        col += starBright * vec3(0.9, 0.95, 1.0);
    }

    // 外围星星
    vec2 outerGrid = floor(texCoord * 50.0);
    float outerStar = hash2(outerGrid + 500.0);
    if (outerStar > 0.96 && dist > 0.4) {
        vec2 sp = fract(texCoord * 50.0) - 0.5;
        col += smoothstep(0.1, 0.0, length(sp)) * 0.4;
    }

    col = col / (col + 0.5);
    vec3 finalColor = clamp(col * color, 0.0, 1.0);

    if (centerCol.a != 0.0) {
        fragColor = vec4(finalColor, mixFactor);
    } else {
        float alpha = glowShader();
        fragColor = vec4(finalColor, alpha);
    }
}