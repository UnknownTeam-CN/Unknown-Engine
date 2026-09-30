package options;

import backend.Language;

class ExperimentalSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('options_Experimental', 'Experimental Options');
		rpcTitle = 'Experimental Options Menu'; //for Discord Rich Presence

		// 音频支持扩展：开启后允许加载 OGG 以外的音频格式（MP3/WAV/FLAC 等）
		var option:Option = new Option('Audio Support Extend', 'Allows loading audio files in formats other than OGG (MP3, WAV, FLAC). May not work on all platforms.', 'audioSupportExtend', BOOL, null, 'audio_support_extend');
		addOption(option);

		super();
	}
}
