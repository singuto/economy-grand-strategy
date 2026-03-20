shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

/// Model-space sphere radius after displacement (quadsphere verts are normalized to this shell).
uniform float globe_radius : hint_range(0.1, 100.0) = 1.0;
uniform float height_scale : hint_range(0.0, 1.0) = 0.05;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float specular : hint_range(0.0, 1.0) = 0.45;
/// Blend between smoothed sphere normal (0) and cubemap normal (1).
uniform float normal_detail : hint_range(0.0, 1.0) = 1.0;

uniform vec3 ambient_tint : source_color = vec3(1.0, 1.0, 1.0);

/// Thin-film style limb glow (emission, reads well on dark UI backgrounds).
uniform vec3 rim_color : source_color = vec3(0.35, 0.6, 1.0);
uniform float rim_intensity : hint_range(0.0, 4.0) = 1.15;
uniform float rim_power : hint_range(0.1, 8.0) = 3.5;

uniform samplerCube albedo_cubemap : source_color, filter_linear_mipmap_anisotropic;
uniform samplerCube normal_cubemap : hint_normal, filter_linear_mipmap_anisotropic;
uniform samplerCube height_cubemap : hint_default_black, filter_linear_mipmap_anisotropic;

varying vec3 v_sphere_dir;

void vertex() {
	vec3 dir = normalize(VERTEX);
	v_sphere_dir = dir;

	vec3 up = abs(dir.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
	vec3 t = normalize(cross(up, dir));
	vec3 b = cross(dir, t);
	TANGENT = t;
	BINORMAL = b;

	float h = textureLod(height_cubemap, dir, 0.0).r;
	float disp = (h - 0.5) * 2.0 * height_scale;
	VERTEX = dir * (globe_radius + disp);
	NORMAL = dir;
}

void fragment() {
	vec3 dir = normalize(v_sphere_dir);
	vec3 n0 = normalize(NORMAL);
	vec3 t = normalize(TANGENT);
	vec3 b = normalize(BINORMAL);
	vec3 tsn = texture(normal_cubemap, dir).xyz * 2.0 - 1.0;
	vec3 n_det = normalize(tsn.x * t + tsn.y * b + tsn.z * n0);
	NORMAL = normalize(mix(n0, n_det, normal_detail));

	ALBEDO = texture(albedo_cubemap, dir).rgb * ambient_tint;

	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - ndv, rim_power);
	EMISSION = rim_color * rim * rim_intensity;

	ROUGHNESS = roughness;
	METALLIC = 0.0;
	SPECULAR = specular;
}
