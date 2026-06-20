shader_type canvas_item;

uniform vec4 shield_color : source_color = vec4(0.0, 0.6, 1.0, 1.0);
uniform sampler2D noise_tex : repeat_enable;
uniform float speed = 0.5;
uniform float pulse_frequency = 2.0;

void fragment() {
    vec4 main_tex = texture(TEXTURE, UV);
    
    vec2 moving_uv = UV + vec2(TIME * speed, TIME * speed * 0.5);
    float noise = texture(noise_tex, moving_uv).r;
    
    float pulse = sin(TIME * pulse_frequency) * 0.15 + 0.85;
	
	float bubble_edge = main_tex.a;
    
    COLOR.rgb = shield_color.rgb;
    COLOR.a = bubble_edge * noise * pulse * shield_color.a * 2.0;
}