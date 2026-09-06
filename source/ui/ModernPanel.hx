package ui;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

/**
	ModernPanel — rounded translucent "glass" card.
	Fill color is CARD_FILL; set .alpha (default CARD_ALPHA) for the glass look.
 */
class ModernPanel extends FlxSprite
{
	public function new(x:Float, y:Float, w:Float, h:Float, ?radius:Int = 0, ?fill:Int = 0)
	{
		super(x, y);
		if (fill == 0) fill = ModernTheme.CARD_FILL;
		if (radius <= 0) radius = ModernTheme.RADIUS;
		makeGraphic(Std.int(w), Std.int(h), FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(this, 0, 0, w, h, radius, radius, fill);
		alpha = ModernTheme.CARD_ALPHA;
		scrollFactor.set();
		antialiasing = true;
	}
}
