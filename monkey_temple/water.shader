/*
MIT License

Copyright (c) 2019 - 2020 Dimas "Dimev", "Skythedragon" Leenman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

shader_type spatial;
render_mode depth_draw_always, diffuse_lambert, specular_schlick_ggx;

uniform vec4 water_color : hint_color = vec4(0.01, 0.02, 0.05, 0.0);
uniform float absorbsion = 0.3;
uniform float wave_sharpness = 0.08;
uniform float wave_height = 4.0;
uniform float wave_size = 0.03;
uniform float wave_speed = 0.5;
uniform float foam_depth = 0.5;

// from https://www.shadertoy.com/view/MdXyzX
vec2 wavedx(vec2 position, vec2 direction, float speed, float frequency, float timeshift) {
    float x = dot(direction, position) * frequency + timeshift * speed;
    float wave = exp(sin(x) - 1.0);
    float dx = wave * cos(x);
    return vec2(wave, -dx);
}

float get_waves(vec2 position, int iterations, float time){
	float iter = 0.0;
    float phase = 6.0;
    float speed = 2.0;
    float weight = 1.0;
    float w = 0.0;
    float ws = 0.0;
    for(int i=0;i<iterations;i++){
        vec2 p = vec2(sin(iter), cos(iter));
        vec2 res = wavedx(position, p, speed, phase, time);
        position += normalize(p) * res.y * weight * wave_sharpness;
        w += res.x * weight;
        iter += 12.0;
        ws += weight;
        weight = mix(weight, 0.0, 0.2);
        phase *= 1.18;
        speed *= 1.07;
    }
    return w / ws;
}

void vertex() {
	
	vec3 vert_offset = NORMAL * (get_waves(VERTEX.xz * wave_size, 8, TIME * wave_speed) * wave_height - wave_height);
	VERTEX += vert_offset;
	
}

void fragment() {
	
	float depth_raw = texture(DEPTH_TEXTURE, SCREEN_UV).r * 2.0 - 1.0;
	float depth = (PROJECTION_MATRIX[3][2] / (depth_raw + PROJECTION_MATRIX[2][2])) + VERTEX.z;
	vec3 pixel_pos = VIEW * depth;
	
	// low poly normal
	NORMAL = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	
	float transmittance = 1.0 - clamp(exp(-absorbsion * depth), 0.0, 1.0);
	
	if (depth < foam_depth) {
		ALBEDO = vec3(1.0);
		ALPHA = 1.0;
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
		METALLIC = 0.0;
	} else {	
		ALBEDO = water_color.xyz;
		ALPHA = transmittance;
		TRANSMISSION = water_color.xyz;
		ROUGHNESS = 0.0;
		SPECULAR = 1.0;
		METALLIC = 0.0;
	}
}