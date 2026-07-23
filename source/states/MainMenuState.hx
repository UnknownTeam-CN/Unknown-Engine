package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0.4';
	public static var UnknownEngineVersion:String = 'Beta 0.1';
	public static var curSelected:Int = 0;

	var menuItems:Array<String> = [
		'Story Mode',
		'Freeplay',
		#if MODS_ALLOWED 'Mods', #end
		'Credits',
		'Options'
	];
	var menuKeys:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		'credits',
		'options'
	];

	var menuTexts:Array<FlxText> = [];

	var bg:FlxSprite;
	var magenta:FlxSprite;
	var camFollow:FlxObject;

	static var showOutdatedWarning:Bool = true;

	override function create()
	{
		super.create();

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = 0.25;
		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		// Menu items - left-aligned, 80px from left
		var startX:Float = 80;
		var startY:Float = 120;
		var spacing:Float = 72;

		for (i in 0...menuItems.length)
		{
			var text = new FlxText(startX, startY + i * spacing, 0, menuItems[i], 48);
			text.setFormat(Paths.font('game_font.ttf'), 48, FlxColor.WHITE, LEFT);
			text.antialiasing = ClientPrefs.data.antialiasing;
			text.scrollFactor.set();
			add(text);
			menuTexts.push(text);
		}

		// Version texts
		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.LIME, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);

		var UEVer:FlxText = new FlxText(12, FlxG.height - 64, 0, "Unknown Engine " + UnknownEngineVersion, 12);
		UEVer.scrollFactor.set();
		UEVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.CYAN, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(UEVer);

		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);

		updateSelection();

		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');
		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		#if CHECK_FOR_UPDATES
		if (showOutdatedWarning && ClientPrefs.data.checkForUpdates && substates.OutdatedSubState.updateVersion != psychEngineVersion) {
			persistentUpdate = false;
			showOutdatedWarning = false;
			openSubState(new substates.OutdatedSubState());
		}
		#end

		FlxG.camera.follow(camFollow, null, 0.15);
	}

	var selectedSomethin:Bool = false;
	var timeNotMoving:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				curSelected = FlxMath.wrap(curSelected - 1, 0, menuTexts.length - 1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				updateSelection();
			}

			if (controls.UI_DOWN_P)
			{
				curSelected = FlxMath.wrap(curSelected + 1, 0, menuTexts.length - 1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				updateSelection();
			}

			// Mouse hover
			if ((FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed)
			{
				FlxG.mouse.visible = true;
				timeNotMoving = 0;
				for (i in 0...menuTexts.length)
				{
					if (FlxG.mouse.overlaps(menuTexts[i]) && curSelected != i)
					{
						curSelected = i;
						FlxG.sound.play(Paths.sound('scrollMenu'));
						updateSelection();
						break;
					}
				}
			}
			else
			{
				timeNotMoving += elapsed;
				if (timeNotMoving > 2) FlxG.mouse.visible = false;
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT || FlxG.mouse.justPressed)
			{
				// Check if mouse click is on any menu item
				var clickedIdx:Int = -1;
				if (FlxG.mouse.justPressed)
				{
					for (i in 0...menuTexts.length)
					{
						if (FlxG.mouse.overlaps(menuTexts[i]))
						{
							clickedIdx = i;
							break;
						}
					}
					if (clickedIdx == -1) return;
					curSelected = clickedIdx;
					updateSelection();
				}

				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedSomethin = true;
				FlxG.mouse.visible = false;

				if (ClientPrefs.data.flashing)
					FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				var targetText = menuTexts[curSelected];
				var targetKey = menuKeys[curSelected];

				FlxFlicker.flicker(targetText, 1, 0.06, false, false, function(flick:FlxFlicker)
				{
					switch (targetKey)
					{
						case 'story_mode':
							MusicBeatState.switchState(new StoryMenuState());
						case 'freeplay':
							MusicBeatState.switchState(new FreeplayState());
						#if MODS_ALLOWED
						case 'mods':
							MusicBeatState.switchState(new ModsMenuState());
						#end
						case 'credits':
							MusicBeatState.switchState(new CreditsState());
						case 'options':
							MusicBeatState.switchState(new OptionsState());
							OptionsState.onPlayState = false;
							if (PlayState.SONG != null)
							{
								PlayState.SONG.arrowSkin = null;
								PlayState.SONG.splashSkin = null;
								PlayState.stageUI = 'normal';
							}
						default:
							selectedSomethin = false;
					}
				});

				for (text in menuTexts)
				{
					if (text != targetText)
						FlxTween.tween(text, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
				}
			}

			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function updateSelection()
	{
		for (i in 0...menuTexts.length)
		{
			if (i == curSelected)
			{
				menuTexts[i].color = FlxColor.YELLOW;
				menuTexts[i].size = 56;
				camFollow.y = menuTexts[i].y + menuTexts[i].height / 2;
			}
			else
			{
				menuTexts[i].color = FlxColor.WHITE;
				menuTexts[i].size = 48;
			}
		}
	}
}
