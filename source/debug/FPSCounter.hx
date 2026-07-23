package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.system.System;
import openfl.Assets;
import openfl.text.Font;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;

	@:noCompletion private var times:Array<Float>;

	// colorfps place
	private var hue:Float = 0;
	private var colorfulFPS:Bool = false;
	private var colorfulFPSSpeed:Float = 6;

	// CPU usage tracking
	private var _lastCpuTime:Float = 0;
	private var _lastRealTime:Float = 0;
	private var _cpuUsage:Float = 0;
	private var _cpuSampleTimer:Float = 0;

	// Peak memory
	private var _peakMemory:Float = 0;

	// Custom font name (set after font registration)
	private static var _fpsFontName:String = "_sans";
	private static var _fpsFontLoaded:Bool = false;

	/** 是否显示额外系统信息（CPU/线程/峰值内存）**/
	public var showExtraInfo:Bool = true;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;

		// 尝试加载自定义字体 fps.ttf
		loadFpsFont();

		defaultTextFormat = new TextFormat(_fpsFontName, 14, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		times = [];

		#if cpp
		_lastCpuTime = cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_CURRENT);
		_lastRealTime = haxe.Timer.stamp();
		#end
	}

	/** 注册并加载 fps.ttf 自定义字体 **/
	private function loadFpsFont():Void
	{
		if (_fpsFontLoaded) return;

		try
		{
			// 检查字体文件是否存在（支持 Mods 目录和 assets/fonts/）
			var fontPaths:Array<String> = [
				'assets/fonts/fps.ttf',
				#if MODS_ALLOWED
				'mods/${backend.Mods.currentModDirectory}/fonts/fps.ttf',
				#end
			];

			for (path in fontPaths)
			{
				if (sys.FileSystem.exists(path))
				{
					var font:Font = Font.fromFile(path);
					if (font != null)
					{
						Font.registerFont(Type.getClass(font));
						_fpsFontName = font.fontName;
						_fpsFontLoaded = true;
						trace('[FPSCounter] Loaded custom font: $path -> ${_fpsFontName}');
						return;
					}
				}
			}

			// 回退到嵌入 asset（如果通过 project.xml 嵌入了 fps.ttf）
			if (Assets.exists('fonts/fps.ttf', openfl.utils.AssetType.FONT))
			{
				var font:Font = Assets.getFont('fonts/fps.ttf');
				if (font != null)
				{
					_fpsFontName = font.fontName;
					_fpsFontLoaded = true;
					trace('[FPSCounter] Loaded embedded font: fonts/fps.ttf → ${_fpsFontName}');
					return;
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('[FPSCounter] Failed to load fps.ttf: $e');
		}

		// 未找到则使用系统字体
		_fpsFontName = "_sans";
		_fpsFontLoaded = true;
		trace('[FPSCounter] Using default font _sans');
	}

	var deltaTimeout:Float = 0.0;

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();

		// CPU 采样（每 500ms 更新一次，减少开销）
		_cpuSampleTimer += deltaTime;
		if (_cpuSampleTimer >= 500)
		{
			_updateCpuUsage();
			_cpuSampleTimer = 0;
		}

		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 50) {
			deltaTimeout += deltaTime;
			return;
		}

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		updateText();
		deltaTimeout = 0.0;
	}

	/**
	 * 更新 CPU 占用率（基于 hxcpp GC 时间估算，作为进程活跃度指标）
	 * 在 Windows 上通过 Sys.cpuTime() 获取进程 CPU 时间
	 */
	private function _updateCpuUsage():Void
	{
		#if cpp
		var nowReal:Float = haxe.Timer.stamp();
		var nowCpu:Float = Sys.cpuTime();

		var realDelta:Float = nowReal - _lastRealTime;
		var cpuDelta:Float = nowCpu - _lastCpuTime;

		if (realDelta > 0)
			_cpuUsage = Math.min(cpuDelta / realDelta * 100, 100);

		_lastRealTime = nowReal;
		_lastCpuTime = nowCpu;

		// 更新峰值内存
		var mem:Float = memoryMegas;
		if (mem > _peakMemory) _peakMemory = mem;
		#end
	}

	public dynamic function updateText():Void { // so people can override it in hscript
		var memStr:String = flixel.util.FlxStringUtil.formatBytes(memoryMegas);

		text = 'FPS: ${currentFPS}'
			+ '\nMemory: $memStr';

		if (showExtraInfo)
		{
			#if cpp
			// 第1条：进程 CPU 使用率
			text += '\nCPU: ${Math.round(_cpuUsage)}%';

			// 第2条：GC 峰值内存
			text += '\nPeak Mem: ${flixel.util.FlxStringUtil.formatBytes(_peakMemory)}';

			// 第3条：GC 已分配（reserved）总量，反映 GC 堆大小
			var gcReserved:Float = cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_RESERVED);
			text += '\nGC Heap: ${flixel.util.FlxStringUtil.formatBytes(gcReserved)}';
			#end
		}

		// Get the coloFPS realized
		if (colorfulFPS)
		{
			textColor = hslToHex(hue);
			hue += colorfulFPSSpeed;
			if (hue >= 360) hue = 0;
		}
		else
		{
			textColor = 0xFFFFFFFF;
			if (currentFPS < FlxG.drawFramerate * 0.5)
				textColor = 0xFFFF0000;
		}
	}

	// HSL转Hex颜色
	private function hslToHex(h:Float):Int
	{
		var s:Float = 1;
		var l:Float = 0.5;

		var c:Float = (1 - Math.abs(2 * l - 1)) * s;
		var x:Float = c * (1 - Math.abs((h / 60) % 2 - 1));
		var m:Float = l - c / 2;

		var r:Float = 0;
		var g:Float = 0;
		var b:Float = 0;

		if (h >= 0 && h < 60) {
			r = c; g = x; b = 0;
		} else if (h >= 60 && h < 120) {
			r = x; g = c; b = 0;
		} else if (h >= 120 && h < 180) {
			r = 0; g = c; b = x;
		} else if (h >= 180 && h < 240) {
			r = 0; g = x; b = c;
		} else if (h >= 240 && h < 300) {
			r = x; g = 0; b = c;
		} else {
			r = c; g = 0; b = x;
		}

		var ri:Int = Math.floor((r + m) * 255);
		var gi:Int = Math.floor((g + m) * 255);
		var bi:Int = Math.floor((b + m) * 255);

		return (ri << 16) | (gi << 8) | bi;
	}

	// Detect the option is true or not
	public function setColorfulFPS(enabled:Bool):Void
	{
		colorfulFPS = enabled;
	}

	// Set colorful FPS speed
	public function setColorfulFPSSpeed(speed:Float):Void
	{
		colorfulFPSSpeed = speed;
	}

	inline function get_memoryMegas():Float
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
}
