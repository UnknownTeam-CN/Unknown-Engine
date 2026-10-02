package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

/**
 * Fever visualizer: rainbow audio spectrum bars hugging the left and right screen edges.
 *
 * Bars tile the whole screen height and grow inwards. Each bar also owns a soft glow sprite
 * that is taller and longer than the bar itself, so neighbouring glows overlap and blend into
 * a blurred rainbow halo around the spectrum. Two wide edge halos add the ambient rainbow bleed.
 *
 * Real spectrum mode reads PCM straight from the currently playing FlxG.sound.music
 * AudioSource and runs a small radix-2 FFT every frame - no extra haxelib needed.
 * If the AudioSource cannot be reached (paused music, html5, future Flixel changes),
 * it silently falls back to a beat driven fake spectrum so the visuals never break.
 */
class FeverVisualizer extends FlxSpriteGroup
{
	/** How many bars per side. They tile the whole screen height. */
	public static inline var BARS:Int = 48;
	/** Longest bar, as a fraction of the screen width. */
	public static inline var MAX_BAR_LEN_RATIO:Float = 0.26;

	// --- Look / feel knobs (tweak these freely) ---
	/** Opacity of the solid bars. Lower = softer. */
	public static inline var BAR_ALPHA:Float = 0.55;
	/** Opacity of the blurred halo behind each bar. */
	public static inline var GLOW_ALPHA:Float = 0.22;
	/** Opacity of the peak marker. */
	public static inline var PEAK_ALPHA:Float = 0.5;
	/** Opacity of the wide ambient halo bleeding in from the screen edges. */
	public static inline var HALO_ALPHA:Float = 0.16;
	/** How much taller the glow is than its bar (overlap == blur). */
	public static inline var GLOW_HEIGHT_SCALE:Float = 3.5;
	/** Horizontal stretch of the glow beyond the bar length. */
	public static inline var GLOW_LEN_SCALE:Float = 1.15;
	/** Extra glow length in pixels. */
	public static inline var GLOW_LEN_ADD:Float = 10;
	/** Width of the ambient edge halo, relative to the longest bar. */
	public static inline var HALO_LEN_SCALE:Float = 1.6;
	/** Rainbow flow speed, in degrees per second. */
	public static inline var COLOR_FLOW_SPEED:Float = 70;

	static inline var LN10:Float = 2.302585092994046;
	static inline var GLOW_TEX_W:Int = 24;

	/** Fever currently running - drives the fade in/out. */
	public var running:Bool = false;
	/** True while we are reading real PCM data. */
	public var usingRealSpectrum(default, null):Bool = false;
	/** 0..1 fade amount. Applied directly to members: FlxSpriteGroup.alpha multiplies cumulatively. */
	public var fade(default, null):Float = 0;

	public var barValues:Array<Float> = [];
	public var barPeaks:Array<Float> = [];

	var leftBars:Array<FlxSprite> = [];
	var rightBars:Array<FlxSprite> = [];
	var leftGlows:Array<FlxSprite> = [];
	var rightGlows:Array<FlxSprite> = [];
	var leftPeaks:Array<FlxSprite> = [];
	var rightPeaks:Array<FlxSprite> = [];
	var leftHalo:FlxSprite;
	var rightHalo:FlxSprite;

	var glowTexLeft:FlxGraphic;
	var glowTexRight:FlxGraphic;

	#if sys
	var audioSource:lime.media.AudioSource = null;
	#end

	var fftSize:Int = 1024;
	var fftRe:Array<Float> = [];
	var fftIm:Array<Float> = [];
	var windowData:Array<Float> = [];

	var minFreq:Float = 60;
	var maxFreq:Float = 12000;
	// Normalised amplitude is ~0.42 for a full scale sine (Blackman mean gain), i.e. about -7.5 dB.
	var minDb:Float = -70;
	var maxDb:Float = -8;

	var barThickness:Float = 0;
	var maxBarLen:Float = 0;
	var graphicHeight:Int = 1;

	var fakeTime:Float = 0;
	var beatPulse:Float = 0;

	var colorFlow:Float = 0;
	var warnedFallback:Bool = false;
	var avgEnergy:Float = 0;

	public function new()
	{
		super();

		for (i in 0...BARS)
		{
			barValues.push(0);
			barPeaks.push(0);
		}

		buildWindow();
		computeLayout(); // must run before the textures, they are sized from it
		buildGlowTextures();
		buildBars();
		bindMusic();

		fade = 0;
		visible = false;
	}

	function computeLayout():Void
	{
		barThickness = FlxG.height / BARS;
		maxBarLen = FlxG.width * MAX_BAR_LEN_RATIO;
		graphicHeight = Std.int(barThickness) + 1;
		if (graphicHeight < 1) graphicHeight = 1;
	}

	/**
	 * Builds a soft ramp texture: opaque at the screen edge, fading to nothing towards the
	 * middle of the screen. Squared falloff, so it reads as a blur rather than a hard block.
	 */
	function buildGlowTextures():Void
	{
		glowTexLeft = makeRampTexture(true);
		glowTexRight = makeRampTexture(false);
	}

	function makeRampTexture(brightAtLeft:Bool):FlxGraphic
	{
		var bd:BitmapData = new BitmapData(GLOW_TEX_W, graphicHeight, true, 0x00000000);
		for (x in 0...GLOW_TEX_W)
		{
			var t:Float = x / (GLOW_TEX_W - 1);
			if (!brightAtLeft) t = 1 - t;
			var a:Float = (1 - t) * (1 - t);
			var argb:Int = (Std.int(a * 255) << 24) | 0x00FFFFFF;
			for (y in 0...graphicHeight)
				bd.setPixel32(x, y, argb);
		}
		return FlxGraphic.fromBitmapData(bd, true);
	}

	function buildBars():Void
	{
		// Every sprite starts plain white; the rainbow comes from the per-frame `color` tint.
		var yScale:Float = barThickness / graphicHeight;
		var glowThickness:Float = barThickness * GLOW_HEIGHT_SCALE;
		var glowYScale:Float = glowThickness / graphicHeight;

		for (i in 0...BARS)
		{
			var y:Float = i * barThickness;

			var left:FlxSprite = makeBar(0, y, yScale);
			add(left);
			leftBars.push(left);

			var right:FlxSprite = makeBar(FlxG.width, y, yScale);
			add(right);
			rightBars.push(right);

			// Glow sits behind the bar, centered vertically, so it spills over its neighbours.
			var glowY:Float = y - (glowThickness - barThickness) * 0.5;

			var leftGlow:FlxSprite = makeGlow(0, glowY, glowYScale, glowTexLeft);
			add(leftGlow);
			leftGlows.push(leftGlow);

			var rightGlow:FlxSprite = makeGlow(FlxG.width, glowY, glowYScale, glowTexRight);
			add(rightGlow);
			rightGlows.push(rightGlow);

			var leftPeak:FlxSprite = makePeak(0, y, yScale);
			add(leftPeak);
			leftPeaks.push(leftPeak);

			var rightPeak:FlxSprite = makePeak(FlxG.width, y, yScale);
			add(rightPeak);
			rightPeaks.push(rightPeak);
		}

		// Ambient edge halos: one wide rainbow ramp per side, covering the full screen height.
		leftHalo = makeHalo(0, glowTexLeft);
		add(leftHalo);
		rightHalo = makeHalo(FlxG.width, glowTexRight);
		add(rightHalo);
	}

	function makeBar(x:Float, y:Float, yScale:Float):FlxSprite
	{
		var bar:FlxSprite = new FlxSprite(x, y);
		bar.makeGraphic(1, graphicHeight, FlxColor.WHITE);
		bar.origin.set(0, 0);
		bar.scale.y = yScale; // squashed back so the bars tile the screen without seams
		bar.alpha = 0;
		return bar;
	}

	function makeGlow(x:Float, y:Float, yScale:Float, tex:FlxGraphic):FlxSprite
	{
		var glow:FlxSprite = new FlxSprite(x, y);
		glow.loadGraphic(tex);
		glow.origin.set(0, 0);
		glow.scale.y = yScale;
		glow.alpha = 0;
		return glow;
	}

	function makePeak(x:Float, y:Float, yScale:Float):FlxSprite
	{
		var peak:FlxSprite = new FlxSprite(x, y);
		peak.makeGraphic(2, graphicHeight, FlxColor.WHITE);
		peak.origin.set(0, 0);
		peak.scale.y = yScale;
		peak.alpha = 0;
		return peak;
	}

	function makeHalo(x:Float, tex:FlxGraphic):FlxSprite
	{
		var halo:FlxSprite = new FlxSprite(x, 0);
		halo.loadGraphic(tex);
		halo.origin.set(0, 0);
		halo.alpha = 0;
		return halo;
	}

	function buildWindow():Void
	{
		windowData.resize(fftSize);
		fftRe.resize(fftSize);
		fftIm.resize(fftSize);
		for (i in 0...fftSize)
			windowData[i] = 0.42 - 0.50 * Math.cos(2 * Math.PI * i / (fftSize - 1)) + 0.08 * Math.cos(4 * Math.PI * i / (fftSize - 1));
	}

	public function bindMusic():Void
	{
		#if sys
		try
		{
			var music = FlxG.sound.music;
			if (music == null) return;
			// @:privateAccess must sit on the expression itself; flixel keeps _channel internal.
			var chan = @:privateAccess music._channel;
			if (chan == null) return;
			var src = @:privateAccess chan.__audioSource;
			if (src == null || src.buffer == null || src.buffer.data == null) return;
			audioSource = src;
			usingRealSpectrum = true;
		}
		catch (e:Dynamic)
		{
			audioSource = null;
			usingRealSpectrum = false;
		}
		#end
	}

	/** Logs once when the real spectrum is dropped, so the cause is visible in the console. */
	function fallback(reason:String):Void
	{
		if (usingRealSpectrum && !warnedFallback)
		{
			warnedFallback = true;
			FlxG.log.warn('FeverVisualizer: real spectrum unavailable ($reason) - using beat driven fallback.');
		}
		usingRealSpectrum = false;
	}

	/** Called from PlayState.beatHit so the fallback spectrum reacts to the song. */
	public function onBeat():Void
	{
		beatPulse = 1;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var wanted:Float = running ? 1 : 0;
		fade = FlxMath.lerp(fade, wanted, FlxMath.bound(elapsed * 6, 0, 1));
		visible = (fade > 0.01);

		if (!visible)
			return;

		colorFlow += elapsed * COLOR_FLOW_SPEED;
		if (colorFlow >= 360) colorFlow -= 360;

		#if sys
		if (usingRealSpectrum)
			sampleSpectrum(elapsed);
		else
			sampleFake(elapsed);
		#else
		sampleFake(elapsed);
		#end

		applyToBars(elapsed);
	}

	/** Fake spectrum: bass heavy shape driven by the beat, so it still reads as "music". */
	function sampleFake(elapsed:Float):Void
	{
		fakeTime += elapsed;
		beatPulse = Math.max(0, beatPulse - elapsed * 2.5);

		for (i in 0...BARS)
		{
			var phase:Float = fakeTime * (2.0 + i * 0.25) + i * 0.7;
			var wave:Float = Math.sin(phase) * 0.5 + 0.5;
			var energy:Float = Math.pow(1 - i / BARS, 1.2);
			var target:Float = energy * (0.35 + wave * 0.45) * (0.5 + beatPulse * 0.5);

			barValues[i] = FlxMath.lerp(barValues[i], target, FlxMath.bound(elapsed * 12, 0, 1));
			barPeaks[i] = Math.max(barValues[i], barPeaks[i] - elapsed * 0.5);
		}
	}

	#if sys
	function sampleSpectrum(elapsed:Float):Void
	{
		try
		{
			var music = FlxG.sound.music;
			if (music == null || audioSource == null)
			{
				fallback('no music / audio source');
				return;
			}

			var buffer = audioSource.buffer;
			if (buffer == null || buffer.data == null)
			{
				fallback('no decoded buffer');
				return;
			}

			var bitsPerSample:Int = buffer.bitsPerSample;
			var bytesPerSample:Int = Std.int(bitsPerSample / 8);
			var channels:Int = buffer.channels;
			var bytesPerFrame:Int = bytesPerSample * channels;
			if (bytesPerFrame <= 0 || buffer.sampleRate <= 0)
			{
				fallback('unsupported audio format');
				return;
			}

			var data = buffer.data;
			var totalFrames:Int = Std.int(data.length / bytesPerFrame);
			if (totalFrames <= 0)
			{
				fallback('empty buffer');
				return;
			}

			var startFrame:Int = Std.int((music.time / 1000) * buffer.sampleRate);
			if (startFrame < 0) startFrame = 0;

			var n:Int = fftSize;
			for (i in 0...n)
			{
				var frame:Int = startFrame + i;
				var value:Float = 0;
				if (frame < totalFrames)
				{
					var offset:Int = frame * bytesPerFrame;
					for (c in 0...channels)
						value += readSample(data, offset + c * bytesPerSample, bitsPerSample);
					value /= channels;
				}
				fftRe[i] = value * windowData[i];
				fftIm[i] = 0;
			}

			// Radix-2 FFT (in place).
			var nMinusOne:Int = n - 1;
			var j:Int = 0;
			for (i in 0...nMinusOne)
			{
				if (i < j)
				{
					var tr:Float = fftRe[i]; fftRe[i] = fftRe[j]; fftRe[j] = tr;
					var ti:Float = fftIm[i]; fftIm[i] = fftIm[j]; fftIm[j] = ti;
				}
				var k:Int = Std.int(n / 2);
				while (k <= j)
				{
					j -= k;
					k = Std.int(k / 2);
				}
				j += k;
			}

			var half:Int = Std.int(n / 2);
			var len:Int = 2;
			while (len <= n)
			{
				var ang:Float = -2 * Math.PI / len;
				var halfLen:Int = Std.int(len / 2);
				var blockCount:Int = Std.int(n / len);
				for (b in 0...blockCount)
				{
					for (i2 in 0...halfLen)
					{
						var w:Float = ang * i2;
						var wr:Float = Math.cos(w);
						var wi:Float = Math.sin(w);
						var a:Int = b * len + i2;
						var c2:Int = a + halfLen;
						var tr2:Float = fftRe[c2] * wr - fftIm[c2] * wi;
						var ti2:Float = fftRe[c2] * wi + fftIm[c2] * wr;
						fftRe[c2] = fftRe[a] - tr2;
						fftIm[c2] = fftIm[a] - ti2;
						fftRe[a] += tr2;
						fftIm[a] += ti2;
					}
				}
				len = len * 2;
			}

			// Map bins onto logarithmically spaced bars.
			var ampNorm:Float = 2.0 / n; // a full scale sine peaks at ~0.42 after this
			var ratio:Float = maxFreq / minFreq;
			var dbRange:Float = maxDb - minDb;

			for (i in 0...BARS)
			{
				var freqLo:Float = minFreq * Math.pow(ratio, i / BARS);
				var freqHi:Float = minFreq * Math.pow(ratio, (i + 1) / BARS);
				var binLo:Int = Std.int(freqLo * n / buffer.sampleRate);
				var binHi:Int = Std.int(freqHi * n / buffer.sampleRate) + 1;
				if (binLo < 1) binLo = 1;
				if (binHi > half) binHi = half;
				if (binHi <= binLo) binHi = binLo + 1;

				var power:Float = 0;
				var b:Int = binLo;
				while (b < binHi && b < fftRe.length)
				{
					var p:Float = fftRe[b] * fftRe[b] + fftIm[b] * fftIm[b];
					if (p > power) power = p;
					b++;
				}

				// sqrt(power) -> amplitude -> dB. (Using the raw power here is what made every bar pin to max.)
				var amp:Float = Math.sqrt(power) * ampNorm;
				var db:Float = 20 * Math.log(amp + 1e-9) / LN10;
				var value:Float = (db - minDb) / dbRange;
				if (value < 0) value = 0;
				else if (value > 1) value = 1;
				value *= value; // square for extra contrast so quiet bars stay low

				// Snap up instantly, decay smoothly.
				var last:Float = barValues[i];
				if (value < last)
					value = last + (value - last) * FlxMath.bound(elapsed * 12, 0, 1);

				barValues[i] = value;
				barPeaks[i] = Math.max(value, barPeaks[i] - elapsed * 0.5);
			}
		}
		catch (e:Dynamic)
		{
			fallback('exception:' + Std.string(e));
		}
	}

	function readSample(data:lime.utils.UInt8Array, byteOffset:Int, bitsPerSample:Int):Float
	{
		// Manual little-endian byte assembly: lime's UInt8Array has no getInt16/getInt32 instance helpers on native targets.
		switch (bitsPerSample)
		{
			case 16:
				if (byteOffset + 1 >= data.length) return 0;
				var raw:Int = data[byteOffset] | (data[byteOffset + 1] << 8);
				if (raw > 32767) raw -= 65536;
				return raw / 32767.0;

			case 32:
				if (byteOffset + 3 >= data.length) return 0;
				var value:Float = data[byteOffset]
					+ (data[byteOffset + 1] * 256)
					+ (data[byteOffset + 2] * 65536)
					+ (data[byteOffset + 3] * 16777216);
				if (value > 2147483647) value -= 4294967296;
				return value / 2147483647.0;

			case 8:
				if (byteOffset >= data.length) return 0;
				return (data[byteOffset] - 128) / 128.0;
		}
		return 0;
	}
	#end

	function applyToBars(elapsed:Float):Void
	{
		var energySum:Float = 0;

		for (i in 0...BARS)
		{
			var value:Float = barValues[i];
			var len:Float = value * maxBarLen;
			var peakLen:Float = barPeaks[i] * maxBarLen;
			var glowLen:Float = len * GLOW_LEN_SCALE + GLOW_LEN_ADD;

			// Dynamic rainbow: hue spread along the bars and flowing over time, brightness follows the level.
			var hue:Float = (i / BARS) * 360 + colorFlow;
			hue = hue - Math.floor(hue / 360) * 360;
			var col:FlxColor = FlxColor.fromHSB(hue, 0.85, 0.55 + value * 0.45);
			var glowCol:FlxColor = FlxColor.fromHSB(hue, 0.95, 1.0);

			var left:FlxSprite = leftBars[i];
			left.scale.x = len;
			left.x = 0;
			left.color = col;
			left.alpha = fade * BAR_ALPHA;

			var right:FlxSprite = rightBars[i];
			right.scale.x = len;
			right.x = FlxG.width - len;
			right.color = col;
			right.alpha = fade * BAR_ALPHA;

			var glowAlpha:Float = fade * GLOW_ALPHA * (0.25 + value * 0.75);

			var leftGlow:FlxSprite = leftGlows[i];
			leftGlow.scale.x = glowLen / GLOW_TEX_W;
			leftGlow.x = 0;
			leftGlow.color = glowCol;
			leftGlow.alpha = glowAlpha;

			var rightGlow:FlxSprite = rightGlows[i];
			rightGlow.scale.x = glowLen / GLOW_TEX_W;
			rightGlow.x = FlxG.width - glowLen;
			rightGlow.color = glowCol;
			rightGlow.alpha = glowAlpha;

			var leftPeak:FlxSprite = leftPeaks[i];
			leftPeak.x = Math.max(0, Math.min(peakLen, FlxG.width - 2) - 2);
			leftPeak.color = glowCol;
			leftPeak.alpha = barPeaks[i] > 0.02 ? fade * PEAK_ALPHA : 0;

			var rightPeak:FlxSprite = rightPeaks[i];
			rightPeak.x = FlxG.width - Math.min(peakLen, FlxG.width - 2);
			rightPeak.color = glowCol;
			rightPeak.alpha = leftPeak.alpha;

			energySum += value;
		}

		// Ambient halos pulse with the overall level and flow through the rainbow.
		avgEnergy = energySum / BARS;
		var haloLen:Float = maxBarLen * HALO_LEN_SCALE;
		var haloCol:FlxColor = FlxColor.fromHSB(colorFlow, 0.9, 1.0);
		var haloAlpha:Float = fade * HALO_ALPHA * (0.3 + avgEnergy * 0.7);

		leftHalo.scale.x = haloLen / GLOW_TEX_W;
		leftHalo.scale.y = FlxG.height / graphicHeight;
		leftHalo.x = 0;
		leftHalo.color = haloCol;
		leftHalo.alpha = haloAlpha;

		rightHalo.scale.x = haloLen / GLOW_TEX_W;
		rightHalo.scale.y = FlxG.height / graphicHeight;
		rightHalo.x = FlxG.width - haloLen;
		rightHalo.color = haloCol;
		rightHalo.alpha = haloAlpha;
	}

	public function destroySoft():Void
	{
		#if sys
		audioSource = null;
		#end
		running = false;
		fade = 0;
		visible = false;
	}
}
