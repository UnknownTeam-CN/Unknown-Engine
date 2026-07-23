package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSubState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import backend.Paths;
import backend.ClientPrefs;
import backend.Highscore;
import backend.Song;
import states.PlayState;
import states.FreeplayState;
import states.LoadingState;

class ReplayOverSubstate extends MusicBeatSubstate
{
	var bg:FlxSprite;
	var titleText:FlxText;
	var replayText:FlxText;
	var exitText:FlxText;
	var canChoose:Bool = false;

	public function new()
	{
		super();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
		FlxTween.tween(bg, {alpha: 0.75}, 0.4, {ease: FlxEase.quartOut});

		titleText = new FlxText(0, FlxG.height * 0.30, FlxG.width, "REPLAY FINISHED", 48);
		titleText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.alpha = 0;
		titleText.scrollFactor.set();
		add(titleText);
		FlxTween.tween(titleText, {alpha: 1}, 0.4, {ease: FlxEase.quartOut});

		replayText = new FlxText(0, FlxG.height * 0.50, FlxG.width, "Press ACCEPT to Replay Again", 28);
		replayText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.YELLOW, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		replayText.alpha = 0;
		replayText.scrollFactor.set();
		add(replayText);
		FlxTween.tween(replayText, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.3,
			onComplete: function(_) { canChoose = true; }
		});

		exitText = new FlxText(0, FlxG.height * 0.58, FlxG.width, "Press BACK to Exit", 24);
		exitText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		exitText.alpha = 0;
		exitText.scrollFactor.set();
		add(exitText);
		FlxTween.tween(exitText, {alpha: 1}, 0.5, {ease: FlxEase.quartOut, startDelay: 0.5});

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!canChoose) return;

		if (controls.ACCEPT)
		{
			canChoose = false;
			FlxG.sound.music.stop();

			// 重新从 replay 文件加载歌曲，不依赖残留的 PlayState.SONG
			var rep:backend.Replay = PlayState.rep;
			if (rep != null && rep._replayPath != null && sys.FileSystem.exists(rep._replayPath))
			{
				try
				{
					var repJson:Dynamic = haxe.Json.parse(sys.io.File.getContent(rep._replayPath));
					var songName:String = repJson.songName != null ? repJson.songName : "";
					var songDiff:Int = repJson.songDiff != null ? repJson.songDiff : 0;
					var songDiffName:String = repJson.songDiffName != null ? repJson.songDiffName : "";

					var resolvedDiff:Int = songDiff;
					if (songDiffName != "")
					{
						var idx:Int = backend.Difficulty.list.indexOf(songDiffName);
						if (idx >= 0) resolvedDiff = idx;
					}

					var songLowercase:String = backend.Paths.formatToSongPath(songName);
					var poop:String = backend.Highscore.formatSong(songLowercase, resolvedDiff);
					backend.Song.loadFromJson(poop, songLowercase);

					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = resolvedDiff;
					LoadingState.prepareToSong();
					LoadingState.loadAndSwitchState(new PlayState());
				}
				catch (e:Dynamic)
				{
					trace('[ReplayOver] Failed to reload song: ' + e);
					FlxG.sound.play(backend.Paths.sound('cancelMenu'));
				}
			}
			else
			{
				// 回退：复用已有状态
				PlayState.isStoryMode = false;
				LoadingState.prepareToSong();
				LoadingState.loadAndSwitchState(new PlayState());
			}
		}

		if (controls.BACK)
		{
			canChoose = false;
			FlxG.sound.music.stop();
			// 清理回放状态
			PlayState.loadRep = false;
			PlayState.rep = null;
			PlayState.beatHitData = [];
			PlayState.resultsData = null;
			FlxG.switchState(new FreeplayState());
		}
	}
}
