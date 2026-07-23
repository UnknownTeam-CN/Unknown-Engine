package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxStringUtil;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;
import backend.Paths;
import backend.Song;
import backend.Highscore;
import backend.Difficulty;
import states.PlayState;
import states.LoadingState;
import states.FreeplayState;

typedef ReplayFileInfo = {
	var path:String;
	var fileName:String;
	var songName:String;
	var songDiff:Int;
	var songDiffName:String;
	var dateStr:String;
	var noteSpeed:Float;
	var isDownscroll:Bool;
}

class ReplaySelectSubstate extends MusicBeatSubstate
{
	var replays:Array<ReplayFileInfo> = [];
	var curSelected:Int = 0;
	var grpTexts:FlxTypedGroup<FlxText>;
	var bg:FlxSprite;
	var titleText:FlxText;
	var hintText:FlxText;
	var noReplayText:FlxText;
	var targetSongName:String; // 目标曲目名（小写）

	public function new(songName:String)
	{
		super();
		this.targetSongName = Paths.formatToSongPath(songName);

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
		FlxTween.tween(bg, {alpha: 0.75}, 0.3, {ease: FlxEase.quartOut});

		titleText = new FlxText(0, 30, FlxG.width, "REPLAYS - " + songName.toUpperCase(), 40);
		titleText.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.scrollFactor.set();
		add(titleText);

		hintText = new FlxText(0, FlxG.height - 60, FlxG.width,
			"ENTER = Play  |  RESET = Delete  |  BACK = Return", 18);
		hintText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.GRAY, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		hintText.scrollFactor.set();
		add(hintText);

		noReplayText = new FlxText(0, FlxG.height * 0.4, FlxG.width, "No replay files found.\nPlay a song first to generate replays!", 24);
		noReplayText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		noReplayText.scrollFactor.set();
		noReplayText.visible = false;
		add(noReplayText);

		grpTexts = new FlxTypedGroup<FlxText>();
		add(grpTexts);

		loadReplays();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	function loadReplays()
	{
		replays = [];
		var dir:String = 'replays/jsons/$targetSongName';

		if (!FileSystem.exists(dir))
		{
			noReplayText.visible = true;
			noReplayText.text = "No replay files found for '" + targetSongName + "'.\nPlay this song first to generate replays!";
			return;
		}

		try
		{
			for (file in FileSystem.readDirectory(dir))
			{
				if (!StringTools.endsWith(file, ".json")) continue;
				if (file.indexOf("ue_") != 0) continue; // Only Unknown Engine replays

				var filePath:String = '$dir/$file';
				var info:ReplayFileInfo = parseReplayFile(filePath, file);
				if (info != null)
					replays.push(info);
			}
		}
		catch (e:Dynamic)
		{
			trace('Error reading replays: $e');
		}

		// Sort by date, newest first
		replays.sort(function(a:ReplayFileInfo, b:ReplayFileInfo):Int {
			if (a.dateStr > b.dateStr) return -1;
			if (a.dateStr < b.dateStr) return 1;
			return 0;
		});

		if (replays.length == 0)
		{
			noReplayText.visible = true;
			noReplayText.text = "No replay files found for '" + targetSongName + "'.\nPlay this song first to generate replays!";
			return;
		}

		for (i in 0...replays.length)
		{
			var info:ReplayFileInfo = replays[i];
			var diffName:String = (info.songDiffName != null && info.songDiffName != "") ? info.songDiffName.toUpperCase() : "NORMAL";

			var text:FlxText = new FlxText(0, 120 + (i * 50), FlxG.width,
				info.dateStr + "  [" + diffName + "]  -  " + info.noteSpeed + "x Speed", 24);
			text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.ID = i;
			text.scrollFactor.set();
			grpTexts.add(text);
		}

		changeSelection(0, false);
	}

	function parseReplayFile(filePath:String, fileName:String):ReplayFileInfo
	{
		try
		{
			var content:String = File.getContent(filePath);
			var json:Dynamic = Json.parse(content);

			// Extract date from filename: ue_YYYY-MM-DD_...
			var dateStr:String = "Unknown";
			var parts:Array<String> = fileName.split("_");
			if (parts.length >= 2)
			{
				var datePart:String = parts[1]; // YYYY-MM-DD
				if (datePart.length >= 10)
					dateStr = datePart.substr(0, 10);
			}

			return {
				path: filePath,
				fileName: fileName,
				songName: json.songName != null ? json.songName : fileName,
				songDiff: json.songDiff != null ? json.songDiff : 0,
				songDiffName: json.songDiffName != null ? json.songDiffName : "",
				dateStr: dateStr,
				noteSpeed: json.noteSpeed != null ? json.noteSpeed : 1.5,
				isDownscroll: json.isDownscroll != null ? json.isDownscroll : false
			};
		}
		catch (e:Dynamic)
		{
			trace('Failed to parse replay file $filePath: $e');
			return null;
		}
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (replays.length == 0) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, replays.length - 1);
		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		for (text in grpTexts.members)
		{
			text.alpha = 0.4;
			text.color = FlxColor.WHITE;
			if (text.ID == curSelected)
			{
				text.alpha = 1;
				text.color = FlxColor.YELLOW;
			}
		}
	}

	function deleteReplay()
	{
		if (replays.length == 0) return;

		var info:ReplayFileInfo = replays[curSelected];
		try
		{
			if (FileSystem.exists(info.path))
			{
				FileSystem.deleteFile(info.path);
				trace('Deleted replay: ${info.path}');
			}
		}
		catch (e:Dynamic)
		{
			trace('Failed to delete replay: $e');
		}

		// Refresh the list
		grpTexts.clear();
		replays = [];
		loadReplays();
	}

	function playReplay()
	{
		if (replays.length == 0) return;

		var info:ReplayFileInfo = replays[curSelected];
		var songLowercase:String = Paths.formatToSongPath(info.songName);

		// 根据保存的难度名称解析为当前 Difficulty.list 中的正确索引
		var resolvedDiff:Int = info.songDiff;
		if (info.songDiffName != null && info.songDiffName != "")
		{
			var idx:Int = Difficulty.list.indexOf(info.songDiffName);
			if (idx >= 0) resolvedDiff = idx;
		}

		var poop:String = Highscore.formatSong(songLowercase, resolvedDiff);

		// 自主检查：chart 文件是否存在（支持 Mod）
		var chartKey:String = 'data/$songLowercase/$poop.json';
		if (!Paths.fileExists(chartKey, TEXT))
		{
			trace('[Replay] Chart not found: $chartKey');
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}

		// 对齐 FreePlay 启动流程：释放图形缓存
		#if MODS_ALLOWED
		Paths.freeGraphicsFromMemory();
		#end

		// 加载歌曲
		try
		{
			Song.loadFromJson(poop, songLowercase);
		}
		catch (e:haxe.Exception)
		{
			trace('ERROR loading song: ${e.message}');
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}

		// 设置 Replay 对象
		var rep:backend.Replay = new backend.Replay();
		rep._replayPath = info.path;
		rep.replay.songName = info.songName;
		rep.replay.songDiff = resolvedDiff;
		rep.replay.noteSpeed = info.noteSpeed;
		rep.replay.isDownscroll = info.isDownscroll;

		PlayState.loadRep = true;
		PlayState.rep = rep;
		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = resolvedDiff;
		PlayState.chartingMode = false;

		// 不需要手动销毁 FreePlay 的人声
		// 切换 State 后 FreeplayState 会被自动销毁并清理 vocals

		FlxG.sound.music.stop();
		LoadingState.prepareToSong();
		LoadingState.loadAndSwitchState(new PlayState());
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (replays.length == 0)
		{
			if (controls.BACK)
			{
				close();
				return;
			}
			return;
		}

		var shiftMult:Int = 1;
		if (FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (controls.UI_UP_P)
			changeSelection(-shiftMult);
		if (controls.UI_DOWN_P)
			changeSelection(shiftMult);

		if (FlxG.mouse.wheel != 0)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
			changeSelection(-shiftMult * FlxG.mouse.wheel, false);
		}

		if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			playReplay();
		}

		if (controls.RESET)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			deleteReplay();
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}
	}
}
