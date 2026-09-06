package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import openfl.display.BitmapData;

/**
	"Fluid" menu background — stable implementation:
	the accent-gradient bitmap itself is pre-blended (no shader needed), and motion is
	faked by slowly panning the oversized sprite. kick() briefly increases the drift.
 */
class FluidBackground
{
	// palette accents (cyan / pink / light blue)
	public static var COLOR_R:Int = ui.ModernTheme.ACCENT;
	public static var COLOR_G:Int = ui.ModernTheme.ACCENT_PINK;
	public static var COLOR_B:Int = 0xFF7FA8FF;

	public static var FLUID_ENABLED:Bool = true;
	public static var TIME_SPEED:Float = 0.5;
	public static var KICK_BOOST:Float = 3.5;

	static var cachedBmp:BitmapData = null;
	static var layers:Array<FlxSprite> = [];
	static var kicks:Array<Float> = [];
	static var motionTime:Float = 0;

	static var EDGE:Int = 64; // overscan in px so panning never reveals the window edge

	public static function updateMotion(elapsed:Float):Void
	{
		if (layers.length == 0) return;
		var boost:Float = 1;
		for (i in 0...layers.length)
		{
			var s:FlxSprite = layers[i];
			if (s == null) continue;
			var kick:Float = 0;
			if (i < kicks.length) kick = kicks[i];
			if (kick > 0)
			{
				kick -= elapsed * 4.0;
				if (kick < 0) kick = 0;
				kicks[i] = kick;
				boost = 1 + kick * (KICK_BOOST - 1);
			}
			var amp:Float = 14 * boost;
			var ph:Float = i * 1.9;
			s.x = -EDGE + Math.sin(motionTime * 0.7 + ph) * amp;
			s.y = -EDGE + Math.cos(motionTime * 0.55 + ph * 0.7) * amp;
		}
		motionTime += elapsed * TIME_SPEED * boost;
	}

	public static function kick():Void
	{
		for (i in 0...kicks.length)
			kicks[i] = 1;
	}

	public static function create():FlxSprite
	{
		if (!FLUID_ENABLED) return makeBlack();

		var bmp:BitmapData = getBitmap();
		if (bmp == null) return makeBlack();

		var bg:FlxSprite = new FlxSprite().loadGraphic(bmp);
		bg.setGraphicSize(FlxG.width + EDGE * 2, FlxG.height + EDGE * 2);
		bg.updateHitbox();
		bg.x = -EDGE;
		bg.y = -EDGE;
		bg.scrollFactor.set();
		bg.antialiasing = ClientPrefs.data.antialiasing;

		layers.push(bg);
		kicks.push(0);
		return bg;
	}

	static function getBitmap():BitmapData
	{
		if (cachedBmp != null) return cachedBmp;
		cachedBmp = generateBitmap();
		return cachedBmp;
	}

	/** three soft accent glows blended onto a deep slate base */
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
				var cr:Float = r * ((COLOR_R >> 16) & 0xFF) / 255
					+ g * ((COLOR_G >> 16) & 0xFF) / 255
					+ b * ((COLOR_B >> 16) & 0xFF) / 255;
				var cg:Float = r * ((COLOR_R >> 8) & 0xFF) / 255
					+ g * ((COLOR_G >> 8) & 0xFF) / 255
					+ b * ((COLOR_B >> 8) & 0xFF) / 255;
				var cb:Float = r * (COLOR_R & 0xFF) / 255
					+ g * (COLOR_G & 0xFF) / 255
					+ b * (COLOR_B & 0xFF) / 255;

				// subtle vertical gradient for depth
				var vy:Float = 1 - (y / h) * 0.25;
				var fr:Float = 0.03 + cr * 0.75 * vy;
				var fg:Float = 0.045 + cg * 0.75 * vy;
				var fb:Float = 0.08 + cb * 0.75 * vy;
				if (fr > 1) fr = 1;
				if (fg > 1) fg = 1;
				if (fb > 1) fb = 1;

				var col:Int = (0xFF << 24)
					| (Std.int(fr * 255) << 16)
					| (Std.int(fg * 255) << 8)
					| Std.int(fb * 255);
				bmp.setPixel32(x, y, col);
			}
		}
		return bmp;
	}

	static function makeBlack():FlxSprite
	{
		var s:FlxSprite = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
		s.setGraphicSize(FlxG.width, FlxG.height);
		s.updateHitbox();
		return s;
	}
}
