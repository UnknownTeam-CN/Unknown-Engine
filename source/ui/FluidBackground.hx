package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import openfl.display.BitmapData;

/**
	Fluid wave menu background (shader singleton + fresh bitmap per entry).
	Each state entry generates its OWN bitmap (nothing shared with destroyed states),
	and a single long-lived FluidMotionShader is reused for the wave motion.
 */
class FluidBackground
{
	public static var COLOR_R:Int = ui.ModernTheme.ACCENT;
	public static var COLOR_G:Int = ui.ModernTheme.ACCENT_PINK;
	public static var COLOR_B:Int = 0xFF7FA8FF;

	public static var FLUID_ENABLED:Bool = true;
	public static var X_FREQ:Float = 6.0;
	public static var Y_FREQ:Float = 5.0;
	public static var BASE_DIV:Float = 6.0;
	public static var TIME_SPEED:Float = 0.3;
	public static var SPEED_BOOST:Float = 10;

	static var sharedShader:FluidMotionShader = null;
	static var motionTime:Float = 0;

	public static function updateMotion(elapsed:Float):Void
	{
		if (sharedShader == null) return;
		var m:FluidMotionShader = sharedShader;
		var boost:Float = 1;
		if (m.kick > 0)
		{
			m.kick -= elapsed * 4.2;
			if (m.kick < 0) m.kick = 0;
			boost = 1 + m.kick * (SPEED_BOOST - 1);
		}
		m.iTime.value[0] = motionTime;
		m.xwave.value[0] = X_FREQ;
		m.ywave.value[0] = Y_FREQ;
		m.xtime.value[0] = BASE_DIV;
		m.ytime.value[0] = BASE_DIV;
		motionTime += elapsed * TIME_SPEED * boost;
	}

	public static function kick():Void
	{
		if (sharedShader != null) sharedShader.kick = 1;
	}

	public static function create():FlxSprite
	{
		if (!FLUID_ENABLED) return makeBlack();

		// fresh bitmap every entry — never reuse a bitmap that a destroyed state owned
		var bmp:BitmapData = generateBitmap();
		if (bmp == null) return makeBlack();

		if (sharedShader == null)
		{
			sharedShader = new FluidMotionShader();
			sharedShader.iTime.value = [0];
			sharedShader.xwave.value = [X_FREQ];
			sharedShader.ywave.value = [Y_FREQ];
			sharedShader.xtime.value = [BASE_DIV];
			sharedShader.ytime.value = [BASE_DIV];
			sharedShader.uColorR.value = colorToVec(COLOR_R);
			sharedShader.uColorG.value = colorToVec(COLOR_G);
			sharedShader.uColorB.value = colorToVec(COLOR_B);
			sharedShader.kick = 0;
		}

		var bg:FlxSprite = new FlxSprite().loadGraphic(bmp);
		bg.shader = sharedShader;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.scrollFactor.set();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		return bg;
	}

	/** raw RGB channel map; the shader tints R/G/B -> theme accents */
	static function generateBitmap():BitmapData
	{
		var w:Int = 256;
		var h:Int = 144;
		var bmp:BitmapData = new BitmapData(w, h, true, 0xFF000000);
		var centers:Array<Array<Float>> = [[0.22, 0.42], [0.8, 0.3], [0.52, 0.82]];
		for (y in 0...h)
		{
			for (x in 0...w)
			{
				var r:Float = 0;
				var g:Float = 0;
				var b:Float = 0;
				for (i in 0...3)
				{
					var dx:Float = (x / w - centers[i][0]) * 1.85;
					var dy:Float = (y / h - centers[i][1]) * 1.85;
					var v:Float = Math.exp(-(dx * dx + dy * dy) * 3.4);
					if (i == 0) r = v;
					else if (i == 1) g = v;
					else b = v;
				}
				var vy:Float = 1 - (y / h) * 0.2;
				var fr:Float = (0.05 + r * 0.95) * vy;
				var fg:Float = (0.06 + g * 0.95) * vy;
				var fb:Float = (0.09 + b * 0.95) * vy;
				if (fr > 1) fr = 1;
				if (fg > 1) fg = 1;
				if (fb > 1) fb = 1;
				bmp.setPixel32(x, y, (0xFF << 24)
					| (Std.int(fr * 255) << 16)
					| (Std.int(fg * 255) << 8)
					| Std.int(fb * 255));
			}
		}
		return bmp;
	}

	static function colorToVec(c:Int):Array<Float>
	{
		return [
			((c >> 16) & 0xFF) / 255,
			((c >> 8) & 0xFF) / 255,
			(c & 0xFF) / 255
		];
	}

	static function makeBlack():FlxSprite
	{
		var s:FlxSprite = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
		s.setGraphicSize(FlxG.width, FlxG.height);
		s.updateHitbox();
		return s;
	}
}
