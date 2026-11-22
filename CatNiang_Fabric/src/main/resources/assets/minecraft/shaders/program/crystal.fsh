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

vec2 hash2(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

float voronoi(vec2 p, float t) {
    vec2 n = floor(p);
    vec2 f = fract(p);
    float minDist = 1.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = hash2(n + neighbor);
            point = 0.5 + 0.5 * sin(t * 0.5 + 6.2831 * point);
            minDist = min(minDist, length(neighbor + point - f));
        }
    }
    return minDist;
}

float voronoiEdge(vec2 p, float t) {
    vec2 n = floor(p);
    vec2 f = fract(p);
    float d1 = 1.0, d2 = 1.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = hash2(n + neighbor);
            point = 0.5 + 0.5 * sin(t * 0.3 + 6.2831 * point);
            float dist = length(neighbor + point - f);
            if (dist < d1) { d2 = d1; d1 = dist; }
            else if (dist < d2) { d2 = dist; }
        }
    }
    return d2 - d1;
}

void main() {
    vec4 centerCol = texture(DiffuseSampler, texCoord);

    vec2 uv = texCoord - 0.5;
    uv.x *= resolution.x / resolution.y;
    float t = time * 0.4;

    float scale = 4.0 + sin(t * 0.2) * 0.5;
    vec2 p = uv * scale;

    float v = voronoi(p, t);
    float edge = voronoiEdge(p, t);
    float edgeGlow = smoothstep(0.05, 0.0, edge);

    vec2 cellID = floor(p + 0.5);
    vec3 cellColor = vec3(
        0.5 + 0.5 * sin(cellID.x * 1.5 + t),
        0.5 + 0.5 * sin(cellID.y * 1.7 + t * 1.1),
        0.5 + 0.5 * sin((cellID.x + cellID.y) * 0.8 + t * 0.9)
    );
    cellColor = mix(vec3(0.1, 0.2, 0.4), vec3(0.3, 0.6, 0.9), cellColor);

    vec3 col = vec3(0.02, 0.03, 0.08);
    col += cellColor * (0.3 + 0.2 * v);
    col += edgeGlow * vec3(0.7, 0.9, 1.0) * 0.8;
    col += smoothstep(0.4, 0.1, v) * vec3(0.3, 0.5, 0.8) * 0.3;

    float sparkle = smoothstep(0.95, 1.0, sin(t * 3.0 + cellID.x * 10.0 + cellID.y * 7.0));
    col += sparkle * edgeGlow * 0.5;

    vec3 finalColor = clamp(col * color, 0.0, 1.0);

    if (centerCol.a != 0.0) {
        fragColor = vec4(finalColor, mixFactor);
    } else {
        float alpha = glowShader();
        fragColor = vec4(finalColor, alpha);
    }
}