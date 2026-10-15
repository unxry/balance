#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uSurfaceY;
uniform float uDark;

out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 345.45));
  p += dot(p, p + 34.345);
  return fract(p.x * p.y);
}

float noise2(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash21(i);
  float b = hash21(i + vec2(1.0, 0.0));
  float c = hash21(i + vec2(0.0, 1.0));
  float d = hash21(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float softField(vec2 p) {
  float field = 0.58 * noise2(p);
  field += 0.29 * noise2(p * 1.93 + vec2(7.1, 2.8));
  field += 0.13 * noise2(p * 3.71 + vec2(3.4, 9.2));
  return field;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  float depth = clamp((uv.y - uSurfaceY) / max(0.001, 1.0 - uSurfaceY), 0.0, 1.0);
  float t = uTime;

  vec2 drift = vec2(t * 0.019, -t * 0.014);
  vec2 warp = vec2(
    sin(uv.y * 5.2 + t * 0.13),
    sin(uv.x * 4.4 - t * 0.11)
  ) * 0.17;
  float lowerT = 0.0;
  vec2 lowerDrift = vec2(lowerT * 0.019, -lowerT * 0.014);
  vec2 lowerWarp = vec2(
    sin(uv.y * 5.2 + lowerT * 0.13),
    sin(uv.x * 4.4 - lowerT * 0.11)
  ) * 0.136;
  float lowerMix = smoothstep(0.52, 0.84, depth);
  float lowerOpticsT = mix(t, 0.0, lowerMix);
  float detail = mix(
    softField(uv * vec2(7.0, 5.4) + warp + drift),
    softField(uv * vec2(7.0, 5.4) + lowerWarp + lowerDrift),
    lowerMix
  );
  float broad = mix(
    softField(uv * vec2(3.4, 2.6) + warp * 0.6 - drift * 0.7),
    softField(uv * vec2(3.4, 2.6) + lowerWarp * 0.6 - lowerDrift * 0.7),
    lowerMix
  );

  vec3 shallow = vec3(0.34, 0.56, 0.64);
  vec3 deep = uDark > 0.5 ? vec3(0.11, 0.23, 0.29) : vec3(0.09, 0.28, 0.37);
  vec3 color = mix(shallow, deep, smoothstep(0.0, 1.0, depth) * 0.82);
  color += vec3(-0.025, 0.028, 0.043) * (broad - 0.5);

  float causticSeed = mix(
    smoothstep(0.65, 0.78, detail),
    detail,
    lowerMix
  );
  float silver = smoothstep(0.60, 0.79, broad) * (1.0 - smoothstep(0.72, 1.0, depth));
  float warmGlint = smoothstep(0.82, 0.96, broad + 0.035 * sin(lowerOpticsT * 0.061 + uv.x * 5.0));
  float sunX = 0.48 + 0.28 * sin(lowerOpticsT * 0.071);
  float sunPatch = exp(-pow((uv.x - sunX) / 0.18, 2.0) - pow((depth - 0.48) / 0.22, 2.0));
  float coolX = 0.5 + 0.35 * sin(lowerOpticsT * 0.049 + 2.3);
  float coolPatch = exp(-pow((uv.x - coolX) / 0.22, 2.0) - pow((depth - 0.74) / 0.24, 2.0));
  float secondLightX = 0.5 + 0.32 * sin(lowerOpticsT * 0.043 + 4.1);
  float secondLight = exp(-pow((uv.x - secondLightX) / 0.18, 2.0) - pow((depth - 0.72) / 0.27, 2.0));
  float lensAX = 0.22 + 0.04 * sin(lowerOpticsT * 0.037 + 1.2);
  float lensA = exp(-pow((uv.x - lensAX) / 0.11, 2.0) - pow((depth - 0.66) / 0.16, 2.0));
  float lensBX = 0.60 + 0.04 * sin(lowerOpticsT * 0.020 + 3.4);
  float lensB = exp(-pow((uv.x - lensBX) / 0.14, 2.0) - pow((depth - 0.82) / 0.12, 2.0));
  float lensCX = 0.79 + 0.036 * sin(lowerOpticsT * 0.030 + 5.1);
  float lensC = exp(-pow((uv.x - lensCX) / 0.10, 2.0) - pow((depth - 0.43) / 0.14, 2.0));
  float localLens = lensA * 0.18 + lensB * 0.22 + lensC * 0.15;
  float shadowX = 0.5 + 0.31 * sin(lowerOpticsT * 0.052 + 1.6);
  float shadowPatch = exp(-pow((uv.x - shadowX) / 0.17, 2.0) - pow((depth - 0.58) / 0.25, 2.0));
  float lower = smoothstep(0.60, 1.0, depth);
  float leftCorner = exp(-pow((uv.x - 0.08) / 0.11, 2.0) - pow((depth - 0.91) / 0.14, 2.0));
  float rightCorner = exp(-pow((uv.x - 0.92) / 0.11, 2.0) - pow((depth - 0.90) / 0.15, 2.0));
  float cornerLight = max(leftCorner, rightCorner);
  float edgeLens = (exp(-pow((uv.x - 0.025) / 0.022, 2.0)) +
                    exp(-pow((uv.x - 0.975) / 0.022, 2.0))) *
                   smoothstep(0.10, 0.72, depth);
  float lowerCausticGain = mix(1.0, 0.65, lowerMix);
  float caustic = causticSeed * lowerCausticGain * smoothstep(0.05, 0.30, depth) *
                   clamp(0.18 + sunPatch * 0.54 + cornerLight * 0.88 + lower * 0.12, 0.0, 1.0);
  float bright = caustic * 0.78 + silver * 0.08 + sunPatch * 0.08 +
                 secondLight * 0.12 + localLens + cornerLight * 0.74 + edgeLens * 0.24;
  color = mix(color, vec3(0.98, 0.99, 0.99), clamp(bright, 0.0, 0.72));
  color = mix(color, vec3(0.10, 0.31, 0.43), shadowPatch * 0.11 + coolPatch * 0.06);
  color = mix(color, vec3(1.0, 0.97, 0.90), warmGlint * 0.045);

  float alpha = mix(0.64, 0.82, depth) + caustic * 0.045 + edgeLens * 0.035;
  fragColor = vec4(color * alpha, alpha);
}
