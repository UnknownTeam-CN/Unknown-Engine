package ui;

import flixel.system.FlxAssets.FlxShader;

/**
	Shadertoy-style wave distortion for the fluid menu background,
	with per-channel tinting kept on top (R->uColorR, G->uColorG, B->uColorB).
	Ported from "Charming Engine" (Psych 0.6.3 fork) E:\source.
 */
class FluidMotionShader extends FlxShader
{
	/** current feedback strength 0..1 (decays in updateMotion) */
	public var kick:Float = 0;

	@:glFragmentSource('
		#pragma header

		uniform float iTime;
		uniform float xwave;
		uniform float ywave;
		uniform float xtime;
		uniform float ytime;
		uniform vec3 uColorR;
		uniform vec3 uColorG;
		uniform vec3 uColorB;

		void main()
		{
			vec2 iResolution = openfl_TextureSize;
			vec2 fragCoord = openfl_TextureCoordv * openfl_TextureSize;
			vec2 uv = fragCoord.xy / iResolution.xy;

			uv.x += sin(uv.y * xwave + iTime) / xtime;
			uv.y += sin(uv.x * ywave + iTime) / ytime;

			vec4 color = flixel_texture2D(bitmap, uv);

			// per-channel tint (maps the R/G/B "paint" channels onto chosen accents)
			vec3 col = color.r * uColorR + color.g * uColorG + color.b * uColorB;
			col = clamp(col, 0.0, 1.0);

			gl_FragColor = vec4(col, color.a);
		}
	')

	public function new()
	{
		super();
	}
}
