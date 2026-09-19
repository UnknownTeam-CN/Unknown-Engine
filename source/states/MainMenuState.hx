package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import ui.ModernPanel;
import ui.ModernTheme;
import ui.InputMode;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '1.0.4';
	public static var UnknownEngineVersion:String = '1.0.5 Hotfix';
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

	// Modern UI extras
	var overlay:FlxSprite;
	var captionTxt:FlxText;
	var titleTxt:FlxText;
	var selectionBar:FlxSprite;
	var hintTxt:FlxText;
	var lastInputMode:String = 'keyboard';

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

		bg = ui.FluidBackground.create();
		add(bg);

		magenta = new FlxSprite().makeGraphic(1, 1, 0xFFfd719b);
		magenta.scrollFactor.set();
		magenta.setGraphicSize(FlxG.width, FlxG.height);
		magenta.updateHitbox();
		magenta.visible = false;
		magenta.alpha = 0.35;
		add(magenta);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		// --- Dim layer (glass depth) ---
		overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, ModernTheme.OVERLAY);
		overlay.scrollFactor.set();
		overlay.alpha = 0.3;
		add(overlay);

		// --- Modern header (top-left) ---  Anyway, you can modify it from here lol
		captionTxt = new FlxText(64, 64, 0, 'UNKNOWN ENGINE', 18);
		captionTxt.setFormat(Paths.font(ModernTheme.FONT_MONO), 18, ModernTheme.ACCENT, LEFT);
		captionTxt.scrollFactor.set();
		captionTxt.antialiasing = true;
		add(captionTxt);

		titleTxt = new FlxText(62, 92, 0, Language.getPhrase('mainmenu_engine_title', "Unknown Meaning Funkin'"), 48);
		titleTxt.setFormat(Paths.font(ModernTheme.FONT), 48, ModernTheme.TEXT_HI, LEFT);
		titleTxt.scrollFactor.set();
		titleTxt.antialiasing = true;
		add(titleTxt);

		// --- Menu items (right column, flat & minimal) ---
		var colX:Float = FlxG.width * 0.62;
		var startY:Float = 190.0;
		var spacing:Float = 88.0;

		for (i in 0...menuItems.length)
		{
			var text = new FlxText(colX, startY + i * spacing, 0, Language.getPhrase('menu_${menuKeys[i]}', menuItems[i]), 38);
			text.setFormat(Paths.font(ModernTheme.FONT), 38, ModernTheme.TEXT_MID, LEFT);
			text.antialiasing = ClientPrefs.data.antialiasing;
			text.scrollFactor.set();
			add(text);
			menuTexts.push(text);
		}

		selectionBar = new FlxSprite(colX - 30, startY).makeGraphic(5, 46, ModernTheme.ACCENT);
		selectionBar.scrollFactor.set();
		selectionBar.antialiasing = true;
		add(selectionBar);

		// --- Device-aware hint bar (switches between keyboard & gamepad prompts) ---
		hintTxt = new FlxText(0, FlxG.height - 42, FlxG.width, '', 16);
		hintTxt.setFormat(Paths.font(ModernTheme.FONT_MONO), 16, ModernTheme.TEXT_DIM, CENTER);
		hintTxt.scrollFactor.set();
		add(hintTxt);
		refreshInputHint();

		// --- Version chip (bottom-left, glass, camera-fixed) ---
		var verChip:ModernPanel = new ModernPanel(18, FlxG.height - 96, 330, 78);
		verChip.alpha = 0.55;
		add(verChip);

		var UEVer:FlxText = new FlxText(34, verChip.y + 10, 0, Language.getPhrase('mainmenu_unknown_version', "Unknown Engine {1}").replace('{1}', UnknownEngineVersion), 14);
		UEVer.setFormat(Paths.font(ModernTheme.FONT_MONO), 15, ModernTheme.ACCENT, LEFT);
		UEVer.scrollFactor.set();
		add(UEVer);

		var psychVer:FlxText = new FlxText(34, verChip.y + 30, 0, Language.getPhrase('mainmenu_psych_version', "Psych Engine v{1}").replace('{1}', psychEngineVersion), 14);
		psychVer.setFormat(Paths.font(ModernTheme.FONT_MONO), 15, ModernTheme.ACCENT_PINK, LEFT);
		psychVer.scrollFactor.set();
		add(psychVer);

		var fnfVer:FlxText = new FlxText(34, verChip.y + 50, 0, Language.getPhrase('mainmenu_fnf_version', "Friday Night Funkin' v{1}").replace('{1}', Application.current.meta.get('version')), 14);
		fnfVer.setFormat(Paths.font(ModernTheme.FONT_MONO), 15, ModernTheme.TEXT_MID, LEFT);
		fnfVer.scrollFactor.set();
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

	function refreshInputHint()
	{
		if (hintTxt == null) return;
		var upDown:String = InputMode.actionLabel('ui_up') + '/' + InputMode.actionLabel('ui_down');
		var acc:String = InputMode.actionLabel('accept');
		var back:String = InputMode.actionLabel('back');
		hintTxt.text = '$upDown 选择    $acc 确认    $back 返回';
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		InputMode.update();
		if (InputMode.mode() != lastInputMode)
		{
			lastInputMode = InputMode.mode();
			refreshInputHint();
		}

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
		ui.FluidBackground.kick();
		for (i in 0...menuTexts.length)
		{
			var txt = menuTexts[i];
			if (i == curSelected)
			{
				txt.color = ModernTheme.TEXT_HI;
				if (Math.abs(txt.size - 42) > 0.1) FlxTween.tween(txt, {size: 42}, 0.09);
				selectionBar.y = txt.y + txt.height / 2 - selectionBar.height / 2;
				camFollow.y = txt.y + txt.height / 2;
			}
			else
			{
				txt.color = ModernTheme.TEXT_MID;
				if (Math.abs(txt.size - 38) > 0.1) FlxTween.tween(txt, {size: 38}, 0.09);
			}
		}
	}
}
