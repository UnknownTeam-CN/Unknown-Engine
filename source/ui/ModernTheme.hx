package ui;

import flixel.util.FlxColor;

/**
	Shared design tokens for the modern "dark glass" UI.
	Every migrated screen reads colors/fonts from here so the whole
	engine stays visually consistent.
 */
class ModernTheme
{
	// Type
	inline public static var FONT:String = 'RockfordSans-Light.otf';
	inline public static var FONT_MONO:String = 'vcr.ttf';

	// Core palette (deep slate base + cool glass surfaces)
	inline public static var BG_COLOR:Int = 0xFF070B11;
	inline public static var OVERLAY:Int = 0xFF05070C; // dim layer over background art
	inline public static var OVERLAY_ALPHA:Float = 0.55;
	inline public static var CARD_FILL:Int = 0xFF111A26; // apply CARD_ALPHA on the sprite
	inline public static var CARD_ALPHA:Float = 0.82;
	inline public static var CARD_ALT_FILL:Int = 0xFF1B2735;
	inline public static var STROKE:Int = 0x33FFFFFF;

	// Text
	inline public static var TEXT_HI:Int = 0xFFEAF2FF;
	inline public static var TEXT_MID:Int = 0xFF9FB4CC;
	inline public static var TEXT_DIM:Int = 0xFF5E7089;

	// Accents
	inline public static var ACCENT:Int = 0xFF5FD4FF; // cyan
	inline public static var ACCENT_PINK:Int = 0xFFFF6BA8; // magenta (FNF side)

	// Geometry
	inline public static var RADIUS:Int = 16;

	/** Applies `alpha` (0..1) to an opaque 0xRRGGBB color. */
	public static function withAlpha(color:Int, alpha:Float):Int
	{
		if (alpha <= 0) return 0;
		if (alpha >= 1) return color;
		return (Std.int(alpha * 255) << 24) | (color & 0xFFFFFF);
	}
}
