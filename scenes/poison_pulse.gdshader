shader_type canvas_item;

uniform vec4 poison_color : source_color = vec4(0.6, 0.0, 0.8, 1.0);
uniform float pulse_speed = 4.0;
uniform float pulse_strength = 0.6;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	float mix_amount = pulse * pulse_strength;
	
	COLOR.rgb = mix(tex.rgb, poison_color.rgb, mix_amount);
	COLOR.a = tex.a;
}