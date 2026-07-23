package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxImageFrame;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import haxe.crypto.Base64;
import states.PlayState;

class HitGraph extends FlxSprite
{
	public var _w:Int;
	public var _h:Int;
	public var curData:Array<Array<Dynamic>> = [];

	// PE 判定窗口范围 — 从 ClientPrefs 动态获取
	public var minMS:Float = -170;
	public var maxMS:Float = 170;

	// 歌曲总时长（毫秒），由 ResultsScreen 在 updateGraph() 前赋值
	public var songLength:Float = 0;

	public function new(x:Float = 0, y:Float = 0, width:Int = 490, height:Int = 270)
	{
		super(x, y);
		_w = width;
		_h = height;
		makeGraphic(_w, _h, FlxColor.TRANSPARENT, true);
		antialiasing = false;

		// 尝试从 PlayState.ratingsData 获取最大窗口值
		refreshRange();
	}

	// 从 ratingsData 动态计算显示范围
	public function refreshRange():Void
	{
		if (PlayState.instance != null && PlayState.instance.ratingsData != null)
		{
			var maxWindow:Float = 0;
			for (rating in PlayState.instance.ratingsData)
			{
				if (rating.hitWindow != null && rating.hitWindow > maxWindow)
					maxWindow = rating.hitWindow;
			}
			// 设置范围为最大窗口的 1.5 倍，留点边距
			if (maxWindow > 0)
			{
				maxMS = maxWindow * 1.5;
				minMS = -maxWindow * 1.5;
			}
		}
	}

	public function addToHistory(diff:Float, judge:String, time:Float):Void
	{
		curData.push([diff, judge, time]);
	}

	public function updateGraph():Void
	{
		var bd:BitmapData = new BitmapData(_w, _h, true, 0xCC000000);

		var midY:Int = Std.int(_h / 2);
		var range:Float = maxMS - minMS;

		// 绘制中心参考线 (0ms 完美线)
		for (px in 0..._w)
		{
			bd.setPixel32(px, midY, 0x66FFFFFF);
		}

		// PE 风格的判定窗口参考线
		// sick 窗口（约 22-45ms）— 细线
		var sickWin:Float = 45.0;
		if (PlayState.instance != null && PlayState.instance.ratingsData.length > 0)
			sickWin = PlayState.instance.ratingsData[0].hitWindow;

		// good 窗口
		var goodWin:Float = 90.0;
		if (PlayState.instance != null && PlayState.instance.ratingsData.length > 1)
			goodWin = PlayState.instance.ratingsData[1].hitWindow;

		// bad 窗口
		var badWin:Float = 135.0;
		if (PlayState.instance != null && PlayState.instance.ratingsData.length > 2)
			badWin = PlayState.instance.ratingsData[2].hitWindow;

		// 绘制 ±sickWin 辅助线（绿色细线）
		drawHLine(bd, 0, _w, Math.floor(midY - sickWin * (_h / range)), 0x44AAAAAA);
		drawHLine(bd, 0, _w, Math.floor(midY + sickWin * (_h / range)), 0x44AAAAAA);

		// 绘制 ±goodWin 辅助线（黄色细线）
		drawHLine(bd, 0, _w, Math.floor(midY - goodWin * (_h / range)), 0x33FFFF00);
		drawHLine(bd, 0, _w, Math.floor(midY + goodWin * (_h / range)), 0x33FFFF00);

		// 绘制 ±badWin 辅助线（橙色细线）
		drawHLine(bd, 0, _w, Math.floor(midY - badWin * (_h / range)), 0x22FF8800);
		drawHLine(bd, 0, _w, Math.floor(midY + badWin * (_h / range)), 0x22FF8800);

		// 绘制边框
		drawRect(bd, 0, 0, _w, 1, 0x88FFFFFF);
		drawRect(bd, 0, _h - 1, _w, 1, 0x88FFFFFF);
		drawRect(bd, 0, 0, 1, _h, 0x88FFFFFF);
		drawRect(bd, _w - 1, 0, 1, _h, 0x88FFFFFF);

		// 绘制数据点
		// 优先使用外部传入的 songLength（避免 PlayState.instance 已销毁取到 0）
		var useSongLength:Float = (songLength > 0) ? songLength : PlayState.songLength;
		if (useSongLength <= 0) useSongLength = 1;

		for (d in curData)
		{
			var diff:Float = d[0];
			var judge:String = Std.string(d[1]).toLowerCase();
			var time:Float = d[2];

			// X: 时间位置
			var px:Int = Std.int((time / useSongLength) * _w);
			px = Std.int(FlxMath.bound(px, 0, _w - 1));

			// Y: 偏差映射（正值=早=上方，负值=晚=下方）
			var yRatio:Float = (diff - minMS) / range;
			var py:Int = Std.int(yRatio * _h);
			py = Std.int(FlxMath.bound(py, 0, _h - 1));

			// PE 风格颜色
			var color:Int = switch(judge)
			{
				case "sick": 0xFF00FF88;  // 亮绿
				case "good": 0xFFFFFF00;  // 黄色
				case "bad":  0xFFFF8800;  // 橙色
				case "shit": 0xFFFF4444;  // 红色
				default:     0xFF888888;  // 灰色（miss等）
			}

			// 绘制 3x3 方块
			for (dx in -1...2)
			{
				for (dy in -1...2)
				{
					var nx:Int = px + dx;
					var ny:Int = py + dy;
					if (nx >= 0 && nx < _w && ny >= 0 && ny < _h)
						bd.setPixel32(nx, ny, color);
				}
			}
		}

		loadGraphic(bd);
	}

	// 绘制水平线
	function drawHLine(bd:BitmapData, x1:Int, x2:Int, y:Int, color:Int):Void
	{
		if (y < 0 || y >= _h) return;
		for (x in x1...x2)
		{
			bd.setPixel32(x, y, color);
		}
	}

	// 绘制矩形
	function drawRect(bd:BitmapData, x:Int, y:Int, w:Int, h:Int, color:Int):Void
	{
		for (dx in 0...w)
		{
			for (dy in 0...h)
			{
				var nx:Int = x + dx;
				var ny:Int = y + dy;
				if (nx >= 0 && nx < _w && ny >= 0 && ny < _h)
					bd.setPixel32(nx, ny, color);
			}
		}
	}
}
