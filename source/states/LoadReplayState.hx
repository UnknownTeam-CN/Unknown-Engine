package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.system.FlxSound;
import backend.Replay;


class LoadReplayState extends MusicBeatState
{
	var bg:FlxSprite;
	var titleText:FlxText;
	var replayListText:FlxText;
	var infoText:FlxText;
	var enterText:FlxText;

	var replayFiles:Array<String> = [];
	var selectedIndex:Int = 0;

	var music:FlxSound;

	override function create()
	{
		super.create();

		bg = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.7;
		add(bg);

		titleText = new FlxText(20, -80, 0, Language.getPhrase('load_replay_title', 'Load Replay'), 42);
		titleText.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.scrollFactor.set();
		add(titleText);

		replayListText = new FlxText(20, 150, 600, "", 24);
		replayListText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		replayListText.scrollFactor.set();
		add(replayListText);

		infoText = new FlxText(20, FlxG.height - 180, 600, "", 20);
		infoText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.GRAY, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoText.scrollFactor.set();
		add(infoText);

		enterText = new FlxText(FlxG.width - 400, FlxG.height - 60, 0, Language.getPhrase('load_replay_enter', 'ENTER - Load') + "    " + Language.getPhrase('load_replay_esc', 'ESC - Back'), 22);
		enterText.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		enterText.scrollFactor.set();
		add(enterText);

		// 扫描 replay 目录
		scanReplays();

		// 动画
		FlxTween.tween(titleText, {y: 20}, 0.5, {ease: FlxEase.expoOut});

		updateListDisplay();

		// 背景音乐
		music = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		if (music != null)
		{
			music.volume = 0;
			music.play(false, FlxG.random.int(0, Std.int(music.length / 2)));
			FlxG.sound.list.add(music);
		}

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	function scanReplays():Void
	{
		replayFiles = [];
		var reps:Map<String, String> = FlxG.save.data.replays;
		if (reps == null) return;
		for (key in reps.keys())
		{
			replayFiles.push(key);
		}
		replayFiles.reverse();
	}

	function updateListDisplay():Void
	{
		if (replayFiles.length == 0)
		{
			replayListText.text = Language.getPhrase('load_replay_no_replays', 'No replays found.') + "\n" + Language.getPhrase('load_replay_play_to_create', 'Play a song to create one!');
			infoText.text = "";
			return;
		}

		var display:String = "";
		for (i in 0...replayFiles.length)
		{
			var mark:String = (i == selectedIndex) ? ">> " : "   ";
			var f:String = replayFiles[i];
			// 去掉时间戳等
			var name:String = f;
			display += mark + name + "\n";
		}
		replayListText.text = display;

		// 显示选中 replay 的信息
		var selFile:String = replayFiles[selectedIndex];
		try
		{
			var reps:Map<String, String> = FlxG.save.data.replays;
			var jsonStr:String = reps.get(selFile);
			var parsed:Dynamic = haxe.Json.parse(jsonStr);
			var songName:String = parsed.songName;
			var diff:Int = parsed.songDiff;
			var ver:String = parsed.replayGameVer;
			infoText.text = Language.getPhrase('replay_load_info', 'Song: {1} | Diff: {2} | Ver: {3}').replace('{1}', songName).replace('{2}', Std.string(diff)).replace('{3}', ver);
		}
		catch (e:Dynamic)
		{
			infoText.text = selFile;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (music != null && music.volume < 0.5)
			music.volume += 0.01 * elapsed;

		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W)
		{
			if (replayFiles.length > 0)
			{
				selectedIndex = (selectedIndex - 1 + replayFiles.length) % replayFiles.length;
				updateListDisplay();
			}
		}
		if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S)
		{
			if (replayFiles.length > 0)
			{
				selectedIndex = (selectedIndex + 1) % replayFiles.length;
				updateListDisplay();
			}
		}

		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ACCEPT)
		{
			if (replayFiles.length > 0)
			{
				var selectedFile:String = replayFiles[selectedIndex];
				loadAndPlayReplay(selectedFile);
			}
		}

		if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE)
		{
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	function loadAndPlayReplay(fileName:String):Void
	{
		if (music != null) music.fadeOut(0.3);

		var reps:Map<String, String> = FlxG.save.data.replays;
		if (reps != null && reps.exists(fileName))
		{
			var rep:Replay = new Replay(fileName);
			try {
				var json:ReplayJSON = haxe.Json.parse(reps.get(fileName));
				rep.replay = json;
			} catch(e:Dynamic) {
				trace("Failed to load replay: " + e);
			}
			PlayState.rep = rep;
		}
		PlayState.loadRep = true;
		PlayState.beatHitData = [];

		trace("Loading replay: " + fileName);

		LoadingState.loadAndSwitchState(new PlayState());
	}
}
