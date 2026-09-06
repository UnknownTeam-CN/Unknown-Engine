package ui;

import backend.Controls;
import backend.InputFormatter;
import flixel.FlxG;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

/**
	InputMode — thin helper on top of Psych's auto-detected Controls.controllerMode.
	Any bound keyboard key press => keyboard mode; any bound gamepad button => gamepad
	mode (handled by Controls). Mouse activity also switches back to keyboard mode so
	mouse users get keyboard-style hints. Screens use actionLabel()/hint() to render
	device-aware prompts that swap live while playing.
 */
class InputMode
{
	public static inline var KEYBOARD:String = 'keyboard';
	public static inline var GAMEPAD:String = 'gamepad';

	/** Should be called once per frame by screens that accept mouse input. */
	public static function update():Void
	{
		if (FlxG.mouse.justPressed && Controls.instance != null)
			Controls.instance.controllerMode = false;
	}

	public static function isGamepad():Bool
		return Controls.instance != null && Controls.instance.controllerMode;

	public static function isKeyboard():Bool
		return !isGamepad();

	public static function mode():String
		return isGamepad() ? GAMEPAD : KEYBOARD;

	/** First bound key label for an action, e.g. "ENTER", "SPACE". */
	public static function keyboardLabel(action:String):String
	{
		if (Controls.instance == null) return '?';
		var binds:Array<FlxKey> = Controls.instance.keyboardBinds.get(action);
		return (binds != null && binds.length > 0) ? InputFormatter.getKeyName(binds[0]) : '?';
	}

	/** Friendly label for the first bound gamepad button of an action. */
	public static function gamepadLabel(action:String):String
	{
		if (Controls.instance == null) return '?';
		var binds:Array<FlxGamepadInputID> = Controls.instance.gamepadBinds.get(action);
		if (binds == null || binds.length == 0) return '?';
		return friendlyButton(binds[0]);
	}

	public static function friendlyButton(id:FlxGamepadInputID):String
	{
		return switch (id)
		{
			case A: 'A';
			case B: 'B';
			case X: 'X';
			case Y: 'Y';
			case LEFT_SHOULDER: 'LB';
			case RIGHT_SHOULDER: 'RB';
			case LEFT_TRIGGER: 'LT';
			case RIGHT_TRIGGER: 'RT';
			case START: 'START';
			case BACK: 'BACK';
			case DPAD_UP: 'D▲';
			case DPAD_DOWN: 'D▼';
			case DPAD_LEFT: 'D◀';
			case DPAD_RIGHT: 'D▶';
			case LEFT_STICK_DIGITAL_UP: 'LS▲';
			case LEFT_STICK_DIGITAL_DOWN: 'LS▼';
			case LEFT_STICK_DIGITAL_LEFT: 'LS◀';
			case LEFT_STICK_DIGITAL_RIGHT: 'LS▶';
			case LEFT_STICK_CLICK: 'LS';
			case RIGHT_STICK_CLICK: 'RS';
			default: Std.string(id).split('_').join(' ');
		}
	}

	/** Mode-aware label: keyboard shows the key, gamepad shows the button. */
	public static function actionLabel(action:String):String
		return isGamepad() ? gamepadLabel(action) : keyboardLabel(action);
}
