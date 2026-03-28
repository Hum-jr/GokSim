shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// ─── Texture slots ───────────────────────────────────────────────────────────
uniform sampler2D grass_albedo   : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal   : hint_normal,  filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_height   : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_orm      : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;

uniform sampler2D dirt_albedo    : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_normal    : hint_normal,  filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_height    : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_orm       : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;

uniform sampler2D rock_albedo    : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal    : hint_normal,  filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_height    : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_orm       : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;

// ─── Tiling & blend controls ─────────────────────────────────────────────────
uniform float grass_tiling   : hint_range(0.1, 32.0) = 8.0;
uniform float dirt_tiling    : hint_range(0.1, 32.0) = 6.0;
uniform float rock_tiling    : hint_range(0.1, 32.0) = 4.0;

// Slope threshold: surface normal Y below this starts transitioning to rock
uniform float slope_start    : hint_range(0.0, 1.0) = 0.7;
uniform float slope_end      : hint_range(0.0, 1.0) = 0.4;

// Height-blend sharpness (higher = crisper layer edges)
uniform float blend_sharpness : hint_range(0.1, 8.0) = 3.0;

// Dirt mask: vertex color red channel drives grass→dirt transition
uniform float dirt_contrast  : hint_range(0.5, 8.0) = 4.0;

// Wetness (vertex color blue channel)
uniform float wetness_roughness_min : hint_range(0.0, 1.0) = 0.05;
uniform float wetness_darkening     : hint_range(0.0, 0.5) = 0.25;
uniform vec4  wet_tint              : source_color = vec4(0.12, 0.18, 0.25, 1.0);

// ─── Helpers ─────────────────────────────────────────────────────────────────

// Height-based blend: returns a smooth weight for layer A over B
// given their heights hA, hB and a blend mask value m ∈ [0,1]
float height_blend(float hA, float hB, float mask, float sharpness) {
    float a = hA + mask;
    float b = hB + (1.0 - mask);
    float depth = 0.2;
    float ma = max(a, b) - depth;
    float blendA = max(a - ma, 0.0);
    float blendB = max(b - ma, 0.0);
    return pow(blendA / (blendA + blendB + 1e-5), sharpness);
}

// Reorient normal map (RNM) blend — preserves both base and detail normals
vec3 blend_normals_rnm(vec3 n1, vec3 n2) {
    n1 += vec3(0.0, 0.0, 1.0);
    n2 *= vec3(-1.0, -1.0, 1.0);
    return n1 * dot(n1, n2) / n1.z - n2;
}

varying vec3 world_normal;
varying vec3 world_pos;

void vertex() {
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
    world_pos    = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // ── Sample all three layers ──────────────────────────────────────────────
    vec2 uv_grass = UV * grass_tiling;
    vec2 uv_dirt  = UV * dirt_tiling;
    vec2 uv_rock  = UV * rock_tiling;

    vec4 alb_grass = texture(grass_albedo, uv_grass);
    vec4 alb_dirt  = texture(dirt_albedo,  uv_dirt);
    vec4 alb_rock  = texture(rock_albedo,  uv_rock);

    vec3 nrm_grass = texture(grass_normal, uv_grass).xyz * 2.0 - 1.0;
    vec3 nrm_dirt  = texture(dirt_normal,  uv_dirt ).xyz * 2.0 - 1.0;
    vec3 nrm_rock  = texture(rock_normal,  uv_rock ).xyz * 2.0 - 1.0;

    float h_grass  = texture(grass_height, uv_grass).r;
    float h_dirt   = texture(dirt_height,  uv_dirt ).r;
    float h_rock   = texture(rock_height,  uv_rock ).r;

    vec3 orm_grass = texture(grass_orm, uv_grass).rgb;
    vec3 orm_dirt  = texture(dirt_orm,  uv_dirt ).rgb;
    vec3 orm_rock  = texture(rock_orm,  uv_rock ).rgb;

    // ── Slope mask (world-space Y normal) ───────────────────────────────────
    float slope = dot(world_normal, vec3(0.0, 1.0, 0.0));
    // smoothstep so the transition isn't a hard line
    float rock_mask = 1.0 - smoothstep(slope_end, slope_start, slope);

    // ── Dirt mask from vertex color red channel ──────────────────────────────
    // Painters paint red where dirt paths / tire tracks / bare earth should show
    float dirt_mask = clamp(pow(COLOR.r, 1.0 / dirt_contrast), 0.0, 1.0);

    // ── Height-blend grass ↔ dirt ────────────────────────────────────────────
    float w_grass = height_blend(h_grass, h_dirt, 1.0 - dirt_mask, blend_sharpness);

    vec4  alb_gd  = mix(alb_dirt,  alb_grass,  w_grass);
    vec3  nrm_gd  = normalize(mix(nrm_dirt,  nrm_grass,  w_grass));
    vec3  orm_gd  = mix(orm_dirt,  orm_grass,  w_grass);
    float h_gd    = mix(h_dirt,    h_grass,    w_grass);

    // ── Height-blend (grass/dirt) ↔ rock on slopes ───────────────────────────
    float w_rock = height_blend(h_rock, h_gd, rock_mask, blend_sharpness);

    vec4 alb_final = mix(alb_gd,  alb_rock,  w_rock);
    vec3 nrm_final = normalize(mix(nrm_gd,  nrm_rock,  w_rock));
    vec3 orm_final = mix(orm_gd,  orm_rock,  w_rock);

    // ── Wetness (vertex color blue channel) ──────────────────────────────────
    // Wet surfaces: darker albedo, drastically lower roughness, slight blue tint
    float wetness   = COLOR.b;
    float wet_rough = mix(orm_final.g, wetness_roughness_min, wetness);
    vec3  wet_alb   = mix(alb_final.rgb,
                         alb_final.rgb * (1.0 - wetness_darkening) + wet_tint.rgb * wetness,
                         wetness);

    // ── PBR outputs ──────────────────────────────────────────────────────────
    ALBEDO      = wet_alb;
    ROUGHNESS   = wet_rough;
    METALLIC    = orm_final.b;   // most ground is 0, embedded metal flakes possible
    AO          = orm_final.r;
    AO_LIGHT_AFFECT = 0.5;

    // Transform tangent-space normals to view space for Godot's NORMAL output
    NORMAL_MAP  = nrm_final * 0.5 + 0.5;
    NORMAL_MAP_DEPTH = 1.0;
}