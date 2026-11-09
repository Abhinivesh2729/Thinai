// Thinai orb: a glowing sphere of slowly churning light.
//
// Drawn entirely on the GPU, one pass, no textures: a few octaves of value
// noise flowing inside a disc, a fresnel rim, and a soft halo. uEnergy (0..1)
// is the only "state": idle is a slow breath, thinking swirls faster, a reply
// streaming in makes it pulse. Cheap enough to run at the display's refresh
// rate next to the model on an integrated GPU.
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;      // widget size in logical px
uniform float uTime;     // seconds
uniform float uEnergy;   // 0 calm .. 1 excited
uniform vec3 uCore;      // inner colour (brand green)
uniform vec3 uGlow;      // rim/halo colour (mint)
uniform vec3 uDeep;      // shadow colour inside the sphere
uniform float uDark;     // 1 on a dark background, 0 on light

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float amp = 0.5;
  for (int i = 0; i < 4; i++) {
    v += amp * noise(p);
    p = p * 2.03 + vec2(1.7, 9.2);
    amp *= 0.5;
  }
  return v;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  float side = min(uSize.x, uSize.y);
  // Centered coordinates where the orb's radius is ~0.62 of the half-size,
  // leaving room for the halo.
  vec2 p = (frag - 0.5 * uSize) / (0.5 * side);

  float e = clamp(uEnergy, 0.0, 1.0);
  float t = uTime * (0.18 + 0.55 * e);

  // Radius breathes slowly; energy makes the edge wobble a little.
  float ang = atan(p.y, p.x);
  float wobble = 0.012 * sin(ang * 3.0 + t * 2.1) + 0.010 * sin(ang * 5.0 - t * 1.7);
  float radius = 0.62 + 0.015 * sin(uTime * 0.9) + wobble * (0.4 + 1.6 * e);
  float r = length(p);

  // Interior: domain-warped noise, so the light looks like it is flowing.
  vec2 q = p * 1.6;
  vec2 warp = vec2(fbm(q + vec2(0.0, t)), fbm(q + vec2(5.2, -t * 0.8)));
  float flow = fbm(q + 1.8 * warp + vec2(t * 0.6, -t * 0.3));

  // Pseudo-3D shading: brighter toward a light from the upper left.
  float z = sqrt(max(0.0, 1.0 - (r * r) / (radius * radius)));
  vec3 normal = normalize(vec3(p / radius, z + 1e-3));
  float light = clamp(dot(normal, normalize(vec3(-0.45, -0.55, 0.7))), 0.0, 1.0);

  vec3 col = mix(uDeep, uCore, smoothstep(0.25, 0.85, flow));
  col = mix(col, uGlow, smoothstep(0.62, 0.95, flow) * (0.55 + 0.45 * e));
  col *= 0.55 + 0.6 * light;

  // Fresnel rim and a small specular highlight.
  float rim = pow(1.0 - z, 2.4);
  col += uGlow * rim * (0.55 + 0.6 * e);
  float spec = pow(clamp(dot(normal, normalize(vec3(-0.4, -0.6, 0.9))), 0.0, 1.0), 28.0);
  col += vec3(1.0) * spec * 0.35;

  // Anti-aliased edge (about one pixel wide at any size).
  float px = 2.0 / side;
  float body = 1.0 - smoothstep(radius - px, radius + px, r);

  // Halo outside the sphere; stronger with energy and on dark backgrounds.
  float d = max(r - radius, 0.0);
  float halo = exp(-d * (7.5 - 3.0 * e)) * (0.22 + 0.45 * e) * (0.55 + 0.45 * uDark);
  halo *= 1.0 - body;

  vec3 rgb = col * body + uGlow * halo;
  float alpha = clamp(body + halo, 0.0, 1.0);
  // Premultiplied output, as Flutter expects.
  fragColor = vec4(rgb, alpha);
}
