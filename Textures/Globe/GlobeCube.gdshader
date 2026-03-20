shader_type spatial;

/// PBR defaults for Forward+ (engine defaults, listed explicitly).
render_mode diffuse_burley, specular_schlick_ggx, cull_back;

/// Height mapping matches BaseMaterial3D: fragment parallax, not vertex displacement
/// (see `scene/resources/material.cpp` generated code around FEATURE_HEIGHT_MAPPING).

uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float metallic : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform vec3 albedo_tint : source_color = vec3(1.0);

uniform float heightmap_scale : hint_range(-16.0, 16.0, 0.001) = 5.0;
uniform bool heightmap_deep_parallax = false;
uniform int heightmap_min_layers : hint_range(1, 64) = 8;
uniform int heightmap_max_layers : hint_range(1, 64) = 32;
uniform bool heightmap_flip_tangent = false;
uniform bool heightmap_flip_binormal = false;
/// When false: depth = 1.0 - texture.r (Godot default / black = deep). When true: depth = texture.r (FLAG_INVERT_HEIGHTMAP).
uniform bool heightmap_invert = false;
/// Cubemap parallax is direction-based; scale this if the effect is too subtle or too strong vs StandardMaterial3D on a flat mesh.
uniform float heightmap_direction_scale : hint_range(0.0, 4.0, 0.001) = 1.0;

uniform samplerCube albedo_cubemap : filter_linear_mipmap, repeat_disable, source_color;
uniform samplerCube normal_cubemap : filter_linear_mipmap, repeat_disable, hint_normal;
uniform samplerCube height_cubemap : filter_linear_mipmap, repeat_disable, hint_default_black;

varying vec3 v_model_vertex;
/// View direction (fragment toward camera), normalized, in model space — built in vertex where MODEL_MATRIX exists.
varying vec3 v_view_dir_model;


void vertex() {
	v_model_vertex = VERTEX;
	vec3 world_vtx = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 v_world = normalize(cam - world_vtx);
	v_view_dir_model = normalize((inverse(MODEL_MATRIX) * vec4(v_world, 0.0)).xyz);
}


mat3 cubemap_normal_basis(vec3 dir) {
	vec3 n = normalize(dir);
	vec3 up = (abs(n.y) < 0.99) ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
	vec3 t = normalize(cross(up, n));
	vec3 b = cross(n, t);
	return mat3(t, b, n);
}


float heightmap_depth(vec3 sample_dir) {
	float s = texture(height_cubemap, normalize(sample_dir)).r;
	return heightmap_invert ? s : (1.0 - s);
}


/// Same tangent-space view vector and parallax math as StandardMaterial3D, but steers the cubemap direction instead of UV2.
vec3 parallax_cubemap_dir(vec3 base_dir) {
	vec3 n = normalize(base_dir);
	mat3 tbn = cubemap_normal_basis(n);
	vec2 flip = vec2(heightmap_flip_tangent ? -1.0 : 1.0, heightmap_flip_binormal ? -1.0 : 1.0);
	/// Godot uses mat3(TANGENT * flip.x, -BINORMAL * flip.y, NORMAL) — second axis negated.
	vec3 t1 = tbn[0] * flip.x;
	vec3 b1 = -tbn[1] * flip.y;
	vec3 n1 = tbn[2];

	vec3 v_tbn = vec3(dot(v_view_dir_model, t1), dot(v_view_dir_model, b1), dot(v_view_dir_model, n1));
	vec3 view_parallax = normalize(vec3(v_tbn.xy, v_tbn.z));

	if (heightmap_deep_parallax) {
		float num_layers = mix(float(heightmap_max_layers), float(heightmap_min_layers), abs(view_parallax.z));
		float layer_depth = 1.0 / num_layers;
		vec2 p = view_parallax.xy * heightmap_scale * 0.01;
		vec2 delta = p / num_layers;
		vec3 dxyz = -(t1 * delta.x + b1 * delta.y) * heightmap_direction_scale;

		vec3 cur_dir = n;
		float depth = heightmap_depth(cur_dir);
		float current_depth = 0.0;
		while (current_depth < depth) {
			cur_dir = normalize(cur_dir + dxyz);
			depth = heightmap_depth(cur_dir);
			current_depth += layer_depth;
		}

		vec3 prev_dir = normalize(cur_dir - dxyz);
		float after_depth = depth - current_depth;
		float before_depth = heightmap_depth(prev_dir) - current_depth + layer_depth;
		float denom = after_depth - before_depth;
		float weight = abs(denom) > 1e-5 ? after_depth / denom : 0.0;
		return normalize(mix(cur_dir, prev_dir, weight));
	}

	float depth = heightmap_depth(n);
	vec3 lateral = -(t1 * view_parallax.x + b1 * view_parallax.y);
	return normalize(n + lateral * depth * heightmap_scale * 0.01 * heightmap_direction_scale);
}


void fragment() {
	vec3 dir0 = normalize(v_model_vertex);
	vec3 dir = parallax_cubemap_dir(dir0);

	ALBEDO = texture(albedo_cubemap, dir).rgb * albedo_tint;

	vec3 n_ts = texture(normal_cubemap, dir).rgb * 2.0 - 1.0;
	n_ts = normalize(mix(vec3(0.0, 0.0, 1.0), n_ts, normal_strength));
	mat3 tbn = cubemap_normal_basis(dir);
	vec3 world_normal = normalize(MODEL_NORMAL_MATRIX * (tbn * n_ts));
	NORMAL = normalize((VIEW_MATRIX * vec4(world_normal, 0.0)).xyz);

	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
