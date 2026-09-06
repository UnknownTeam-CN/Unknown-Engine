package options;

import states.MainMenuState;
import backend.StageData;
import backend.Controls;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals',
		'Gameplay'
		#if TRANSLATIONS_ALLOWED , 'Language' #end
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	var timeNotMoving:Float = 0;

	function openSelectedSubstate(label:String) {
		switch(label)
		{
			case 'Note Colors':
				openSubState(new options.NotesColorSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Language':
				openSubState(new options.LanguageSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = ui.FluidBackground.create();
		add(bg);

		var ovl:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, ui.ModernTheme.OVERLAY);
		ovl.scrollFactor.set();
		ovl.alpha = 0.18;
		add(ovl);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (num => option in options)
		{
			var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_$option', option), true);
			optionText.screenCenter();
			optionText.y += (92 * (num - (options.length / 2))) + 45;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorLeft.color = ui.ModernTheme.ACCENT;
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		selectorRight.color = ui.ModernTheme.ACCENT;
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		// ---- Mouse support ----
		if ((FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed)
		{
			FlxG.mouse.visible = true;
			timeNotMoving = 0;
			Controls.instance.controllerMode = false;
			for (num => item in grpOptions.members)
			{
				if (FlxG.mouse.overlaps(item) && num != curSelected)
				{
					changeSelection(num - curSelected);
					break;
				}
			}
			if (FlxG.mouse.justPressed)
			{
				var clicked:Int = -1;
				for (num => item in grpOptions.members)
					if (FlxG.mouse.overlaps(item)) { clicked = num; break; }
				if (clicked >= 0)
				{
					curSelected = clicked;
					openSelectedSubstate(options[curSelected]);
				}
			}
		}
		else
		{
			timeNotMoving += elapsed;
			if (timeNotMoving > 2.5) FlxG.mouse.visible = false;
		}

		if (FlxG.mouse.wheel != 0)
		{
			FlxG.mouse.visible = true;
			Controls.instance.controllerMode = false;
			changeSelection(FlxG.mouse.wheel > 0 ? -1 : 1);
		}

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			FlxG.mouse.visible = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else MusicBeatState.switchState(new MainMenuState());
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.55;
			item.color = ui.ModernTheme.TEXT_MID;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				item.color = ui.ModernTheme.TEXT_HI;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}