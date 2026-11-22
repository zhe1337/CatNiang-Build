#version 150

uniform sampler2D DiffuseSampler;
uniform vec2 OutSize;
uniform float BlurRadius;

in vec2 texCoord;
out vec4 fragColor;

float gaussian(float x, float sigma) {
    return exp(-(x * x) / (2.0 * sigma * sigma));
}

void main() {
    vec2 pixelSize = vec2(0.0, 1.0 / OutSize.y);

    float sigma = max(BlurRadius * 0.4, 0.001);
    int radius = int(BlurRadius);

    vec4 colorSum = vec4(0.0);
    float weightSum = 0.0;

    for (int i = -radius; i <= radius; i++) {
        float weight = gaussian(float(i), sigma);
        vec2 offset = pixelSize * float(i);
        vec4 sample = texture(DiffuseSampler, texCoord + offset);

        colorSum += vec4(sample.rgb * sample.a, sample.a) * weight;
        weightSum += weight;
    }

    if (weightSum > 0.0) {
        vec4 result = colorSum / weightSum;
        if (result.a > 0.001) {
            fragColor = vec4(result.rgb / result.a, result.a);
        } else {
            fragColor = vec4(0.0);
        }
    } else {
        fragColor = vec4(0.0);
    }
}