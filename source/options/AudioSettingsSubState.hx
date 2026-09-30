package options;

import backend.Language;

class AudioSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('options_Audio', 'Audio');
		rpcTitle = 'Audio Options Menu'; //for Discord Rich Presence

		// 彩蛋音效：开启后用 assets/shared/sounds/egg 下的隐藏音效替换部分菜单/操作音效
		var option:Option = new Option('Easter Egg Sound', 'Replaces some menu/SFX sounds with the hidden egg sounds. Unlocked via a secret code in Credits.', 'easterEggSound', BOOL, null, 'easter_egg_sound');
		addOption(option);

		super();
	}
}
