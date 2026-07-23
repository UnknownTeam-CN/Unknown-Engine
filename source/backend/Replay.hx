package backend;

import haxe.Json;
import sys.io.File;
import sys.FileSystem;

class Ana
{
	public var hitTime:Float;
	public var nearestNote:Array<Dynamic>;
	public var hit:Bool;
	public var hitJudge:String;
	public var key:Int;

	public function new(_hitTime:Float, _nearestNote:Array<Dynamic>, _hit:Bool, _hitJudge:String, _key:Int)
	{
		hitTime = _hitTime;
		nearestNote = _nearestNote;
		hit = _hit;
		hitJudge = _hitJudge;
		key = _key;
	}
}

class Analysis
{
	public var anaArray:Array<Ana>;

	public function new()
	{
		anaArray = [];
	}

	public function addToArray(hitTime:Float, note:Array<Dynamic>, hit:Bool, hitJudge:String, key:Int)
	{
		anaArray.push(new Ana(hitTime, note, hit, hitJudge, key));
	}
}

typedef ReplayJSON =
{
	public var replayGameVer:String;
	public var timestamp:String;
	public var songName:String;
	public var songId:String;
	public var songDiff:Int;
	public var songNotes:Array<Array<Dynamic>>;
	public var songJudgements:Array<String>;
	public var noteSpeed:Float;
	public var isDownscroll:Bool;
	public var sf:Int;
	public var sm:Bool;
	public var chartPath:String;
	public var ana:Analysis;
	public var replayChar:String;
}

class Replay
{
	public static var version:String = "unknownengine-1.0";

	public var path:String = "";
	public var replay:ReplayJSON;
	public var _replayPath:String = ""; // JSON 文件完整路径 (Unknown Engine)

	public function new(path:String = "")
	{
		this.path = path;
		replay = {
			replayGameVer: version,
			timestamp: Date.now().toString(),
			songName: "No Song Found",
			songId: "",
			songDiff: 0,
			songNotes: [],
			songJudgements: [],
			noteSpeed: 1.5,
			isDownscroll: false,
			sf: 10,
			sm: false,
			chartPath: "",
			ana: new Analysis(),
			replayChar: "bf"
		};
	}

	public static function LoadReplay(filePath:String):Replay
	{
		var rep:Replay = new Replay(filePath);
		rep.LoadFromJSON();
		return rep;
	}

	public function SaveReplay(songName:String, songId:String, diff:Int, notearray:Array<Array<Dynamic>>, judge:Array<String>, ana:Analysis, noteSpeed:Float, isDownscroll:Bool, sf:Int, replayChar:String = "bf"):Void
	{
		var json:ReplayJSON = {
			replayGameVer: version,
			timestamp: Date.now().toString(),
			songName: songName,
			songId: songId,
			songDiff: diff,
			songNotes: notearray,
			songJudgements: judge,
			noteSpeed: noteSpeed,
			isDownscroll: isDownscroll,
			sf: sf,
			sm: false,
			chartPath: "",
			ana: ana,
			replayChar: replayChar
		};

		var data:String = Json.stringify(json, null, "\t");

		var time:Float = Date.now().getTime();
		var fileName:String = "replay-" + songId + "-diff" + diff + "-" + time + ".unknownReplay";
		// 使用 FlxG.save 保存（兼容所有平台）
		if (FlxG.save.data.replays == null)
			FlxG.save.data.replays = new Map<String, String>();
		var reps:Map<String, String> = FlxG.save.data.replays;
		reps.set(fileName, data);
		FlxG.save.data.replays = reps;
		FlxG.save.flush();

		path = fileName;
		trace('Replay saved: $fileName');
	}

	// Unknown Engine: 生成回放 JSON 文件路径
	// 路径格式: replays/jsons/songname/ue_YYYY-MM-DD_songname_diff.json
	public static function makeReplayPath(songName:String, diff:Int):String
	{
		var now:Date = Date.now();
		var dateStr:String = DateTools.format(now, "%Y-%m-%d");
		var diffs:Array<String> = ['easy', 'normal', 'hard'];
		var diffStr:String = (diff >= 0 && diff < diffs.length) ? diffs[diff] : 'normal';
		var songLower:String = Paths.formatToSongPath(songName);
		return 'replays/jsons/$songLower/ue_${dateStr}_${songLower}_${diffStr}.json';
	}

	// Unknown Engine: 保存帧级按键数据到 JSON 文件
	// 保存路径: replays/jsons/songname/ue_YYYY-MM-DD_songname_diff.json
	public function saveInputFrames(songName:String, songId:String, diff:Int,
		inputFrames:Array<Dynamic>, noteSpeed:Float, isDownscroll:Bool, sf:Int, replayChar:String):Void
	{
		try
		{
			var songLower:String = Paths.formatToSongPath(songName);
			var diffName:String = Difficulty.getString(diff, false);
			var json:Dynamic = {
				replayGameVer: version,
				songName: songName,
				songId: songId,
				songDiff: diff,
				songDiffName: diffName,
				noteSpeed: noteSpeed,
				isDownscroll: isDownscroll,
				sf: sf,
				replayChar: replayChar,
				inputs: inputFrames
			};

			var data:String = Json.stringify(json, null, "\t");
			var filePath:String = makeReplayPath(songName, diff);
			_replayPath = filePath;

			// 确保 replays/jsons/songname/ 目录存在
			var dir:String = 'replays/jsons/$songLower';
			if (!sys.FileSystem.exists(dir))
				sys.FileSystem.createDirectory(dir);

			sys.io.File.saveContent(filePath, data);
			trace('Replay inputs saved: $filePath (${inputFrames.length} frames)');
		}
		catch (e:Dynamic)
		{
			trace('Failed to save replay inputs: $e');
		}
	}

	public function LoadFromJSON():Void
	{
		try
		{
			if (path == "" || !sys.FileSystem.exists("assets/replays/" + path))
			{
				trace("Replay file not found: " + path);
				return;
			}
			var content:String = File.getContent("assets/replays/" + path);
			var parsed:Dynamic = Json.parse(content);
			
			// 手动映射到 ReplayJSON 结构
			replay.replayGameVer = parsed.replayGameVer;
			replay.timestamp = parsed.timestamp;
			replay.songName = parsed.songName;
			replay.songId = Reflect.field(parsed, "songId") != null ? parsed.songId : "";
			replay.songDiff = parsed.songDiff;
			replay.songNotes = parsed.songNotes;
			replay.songJudgements = parsed.songJudgements;
			replay.noteSpeed = parsed.noteSpeed;
			replay.isDownscroll = parsed.isDownscroll;
			replay.sf = parsed.sf;
			replay.sm = parsed.sm;
			replay.chartPath = Reflect.field(parsed, "chartPath") != null ? parsed.chartPath : "";
			replay.replayChar = Reflect.field(parsed, "replayChar") != null ? parsed.replayChar : "bf";
			
			// Analysis 反序列化
			if (parsed.ana != null && parsed.ana.anaArray != null)
			{
				replay.ana = new Analysis();
				for (a in cast(parsed.ana.anaArray, Array<Dynamic>))
				{
					replay.ana.anaArray.push(new Ana(a.hitTime, a.nearestNote, a.hit, a.hitJudge, a.key));
				}
			}
			else
			{
				replay.ana = new Analysis();
			}
		}
		catch (e:Dynamic)
		{
			trace("Failed to load replay: " + e);
		}
	}
}
