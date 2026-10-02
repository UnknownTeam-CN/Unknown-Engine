package backend;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.group.FlxGroup;

import objects.Note;
import objects.Character;

enum Countdown
{
	THREE;
	TWO;
	ONE;
	GO;
	START;
}

class BaseStage extends FlxBasic
{
	private var game(get, never):Dynamic;
	public var onPlayState(get, never):Bool;

	// some variables for convenience
	public var paused(get, never):Bool;
	public var songName(get, never):String;
	public var isStoryMode(get, never):Bool;
	public var seenCutscene(get, never):Bool;
	public var inCutscene(get, set):Bool;
	public var canPause(get, set):Bool;
	public var members(get, never):Array<FlxBasic>;

	public var boyfriend(get, never):Character;
	public var dad(get, never):Character;
	public var gf(get, never):Character;
	public var boyfriendGroup(get, never):FlxSpriteGroup;
	public var dadGroup(get, never):FlxSpriteGroup;
	public var gfGroup(get, never):FlxSpriteGroup;

	public var unspawnNotes(get, never):Array<Note>;

	/**
	 * Everything this stage injected into the state. Tracked so a stage can be pulled out
	 * cleanly at runtime (see `setStageHidden` / `destroyStage`), which is what makes
	 * swapping stages mid-song possible.
	 */
	public var ownedObjects:Array<FlxBasic> = [];
	/** Visibility each owned object had right before this stage was hidden (restored by `setStageShown`). */
	var rememberedVisibility:Map<FlxBasic, Bool> = [];
	
	public var camGame(get, never):FlxCamera;
	public var camHUD(get, never):FlxCamera;
	public var camOther(get, never):FlxCamera;

	public var defaultCamZoom(get, set):Float;
	public var camFollow(get, never):FlxObject;

	public function new()
	{
		if(game == null)
		{
			FlxG.log.error('Invalid state for the stage added!');
			destroy();
		}
		else 
		{
			game.stages.push(this);
			super();
			create();
		}
	}

	//main callbacks
	public function create() {}
	public function createPost() {}
	//public function update(elapsed:Float) {}
	public function countdownTick(count:Countdown, num:Int) {}
	public function startSong() {}

	// FNF steps, beats and sections
	public var curBeat:Int = 0;
	public var curDecBeat:Float = 0;
	public var curStep:Int = 0;
	public var curDecStep:Float = 0;
	public var curSection:Int = 0;
	public function beatHit() {}
	public function stepHit() {}
	public function sectionHit() {}

	// Substate close/open, for pausing Tweens/Timers
	public function closeSubState() {}
	public function openSubState(SubState:FlxSubState) {}

	// Events
	public function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float) {}
	public function eventPushed(event:EventNote) {}
	public function eventPushedUnique(event:EventNote) {}

	// Note Hit/Miss
	public function goodNoteHit(note:Note) {}
	public function opponentNoteHit(note:Note) {}
	public function noteMiss(note:Note) {}
	public function noteMissPress(direction:Int) {}

	// Things to replace FlxGroup stuff and inject sprites directly into the state
	/** Marks `object` as owned by this stage so hiding/showing/destroying the stage touches it too. */
	public function track(object:FlxBasic)
	{
		if (object != null && ownedObjects.indexOf(object) < 0)
			ownedObjects.push(object);
		return object;
	}

	function untrack(object:FlxBasic)
	{
		if (object != null) ownedObjects.remove(object);
		return object;
	}

	function add(object:FlxBasic) { track(object); return FlxG.state.add(object); }
	function remove(object:FlxBasic, splice:Bool = false) { untrack(object); return FlxG.state.remove(object, splice); }
	function insert(position:Int, object:FlxBasic) { track(object); return FlxG.state.insert(position, object); }

	/** Hides what the stage added and stops its callbacks, keeping everything alive for reuse. */
	public function setStageHidden()
	{
		for (object in ownedObjects)
		{
			if (object == null) continue;
			rememberedVisibility.set(object, object.visible);
			object.visible = false;
		}
		active = false;
	}

	/** Restores a previously hidden stage. */
	public function setStageShown()
	{
		for (object in ownedObjects)
		{
			if (object == null) continue;
			// objects the stage itself keeps hidden stay hidden
			object.visible = rememberedVisibility.exists(object) ? rememberedVisibility.get(object) : true;
		}
		rememberedVisibility.clear();
		active = true;
	}

	/** Pulls every tracked object back out of the state and destroys it. */
	public function destroyStage()
	{
		for (object in ownedObjects)
		{
			if (object == null) continue;
			FlxG.state.remove(object, true);
			object.destroy();
		}
		ownedObjects.resize(0);
		rememberedVisibility.clear();
		active = false;
		exists = false;
	}
	
	public function addBehindGF(obj:FlxBasic) return insert(members.indexOf(game.gfGroup), obj);
	public function addBehindBF(obj:FlxBasic) return insert(members.indexOf(game.boyfriendGroup), obj);
	public function addBehindDad(obj:FlxBasic) return insert(members.indexOf(game.dadGroup), obj);
	public function setDefaultGF(name:String) //Fix for the Chart Editor on Base Game stages
	{
		var gfVersion:String = PlayState.SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1)
		{
			gfVersion = name;
			PlayState.SONG.gfVersion = gfVersion;
		}
	}

	public function getStageObject(name:String) //Objects can only be accessed *after* create(), use createPost() if you want to mess with them on init
		return game.variables.get(name);

	//start/end callback functions
	public function setStartCallback(myfn:Void->Void)
	{
		if(!onPlayState) return;
		PlayState.instance.startCallback = myfn;
	}
	public function setEndCallback(myfn:Void->Void)
	{
		if(!onPlayState) return;
		PlayState.instance.endCallback = myfn;
	}

	// overrides
	function startCountdown() if(onPlayState) return PlayState.instance.startCountdown(); else return false;
	function endSong() if(onPlayState)return PlayState.instance.endSong(); else return false;
	function moveCameraSection() if(onPlayState) PlayState.instance.moveCameraSection();
	function moveCamera(isDad:Bool) if(onPlayState) PlayState.instance.moveCamera(isDad);
	inline private function get_paused() return game.paused;
	inline private function get_songName() return game.songName;
	inline private function get_isStoryMode() return PlayState.isStoryMode;
	inline private function get_seenCutscene() return PlayState.seenCutscene;
	inline private function get_inCutscene() return game.inCutscene;
	inline private function set_inCutscene(value:Bool)
	{
		game.inCutscene = value;
		return value;
	}
	inline private function get_canPause() return game.canPause;
	inline private function set_canPause(value:Bool)
	{
		game.canPause = value;
		return value;
	}
	inline private function get_members() return game.members;

	inline private function get_game() return cast FlxG.state;
	inline private function get_onPlayState() return (Std.isOfType(FlxG.state, states.PlayState));

	inline private function get_boyfriend():Character return game.boyfriend;
	inline private function get_dad():Character return game.dad;
	inline private function get_gf():Character return game.gf;

	inline private function get_boyfriendGroup():FlxSpriteGroup return game.boyfriendGroup;
	inline private function get_dadGroup():FlxSpriteGroup return game.dadGroup;
	inline private function get_gfGroup():FlxSpriteGroup return game.gfGroup;

	inline private function get_unspawnNotes():Array<Note>
	{
		return cast game.unspawnNotes;
	}
	
	inline private function get_camGame():FlxCamera return game.camGame;
	inline private function get_camHUD():FlxCamera return game.camHUD;
	inline private function get_camOther():FlxCamera return game.camOther;

	inline private function get_defaultCamZoom():Float return game.defaultCamZoom;
	inline private function set_defaultCamZoom(value:Float):Float
	{
		game.defaultCamZoom = value;
		return game.defaultCamZoom;
	}
	inline private function get_camFollow():FlxObject return game.camFollow;
}
