shader_type spatial;
render_mode unshaded; // For particles, unshaded often looks best

uniform sampler2D particle_texture: hint_default_white;
uniform vec4 fire_color = vec4(1.0, 0.2, 0.0, 1.0); // Bright orange-red
uniform float alpha_power: hint_range(1.0, 10.0) = 3.0; // Controls how fast the edges fade

void fragment() {
    // Get the base color from the particle texture (usually a soft circle)
    vec4 tex_color = texture(particle_texture, UV);

    // Multiply the texture's alpha by the particle's custom alpha (from GPUParticles3D)
    // and by the fire_color's alpha for overall transparency.
    float final_alpha = tex_color.a * COLOR.a;

    // Apply a power to the alpha to make the edges fade more sharply, like fire
    final_alpha = pow(final_alpha, alpha_power);

    // Combine the fire_color with the texture's color (or just use fire_color for a solid tint)
    ALBEDO = fire_color.rgb; // Use the uniform color for the base
    ALBEDO *= tex_color.rgb; // Tint by the texture (optional, makes it less solid)

    ALPHA = final_alpha;
}