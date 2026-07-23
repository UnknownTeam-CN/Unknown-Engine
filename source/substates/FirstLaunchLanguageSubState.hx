package substates;

import backend.Language;

class FirstLaunchLanguageSubState extends MusicBeatSubstate
{
	#if TRANSLATIONS_ALLOWED
	var languages:Array<String> = [];
	var displayLanguages:Map<String, String> = [];
	var curSelected:Int = 0;

	var titleText:FlxText;
	var langNameText:Alphabet;
	var arrowLeft:Alphabet;
	var arrowRight:Alphabet;

	public function new()
	{
		super();

		// 暗色背景
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF111111);
		add(bg);

		// 收集可用语言列表
		languages.push(ClientPrefs.defaultData.language); // en-US
		displayLanguages.set(ClientPrefs.defaultData.language, Language.defaultLangName);

		var directories:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'data/');
		for (directory in directories)
		{
			for (file in FileSystem.readDirectory(directory))
			{
				if (file.toLowerCase().endsWith('.lang'))
				{
					var langFile:String = file.substring(0, file.length - '.lang'.length).trim();
					if (!languages.contains(langFile))
						languages.push(langFile);

					if (!displayLanguages.exists(langFile))
					{
						var path:String = '$directory/$file';
						#if MODS_ALLOWED
						var txt:String = File.getContent(path);
						#else
						var txt:String = Assets.getText(path);
						#end

						var id:Int = txt.indexOf('\n');
						if (id > 0)
						{
							var name:String = txt.substr(0, id).trim();
							if (!name.contains(':'))
								displayLanguages.set(langFile, name);
						}
						else if (txt.trim().length > 0 && !txt.contains(':'))
							displayLanguages.set(langFile, txt.trim());
					}
				}
			}
		}

		// 按显示名称排序
		languages.sort(function(a:String, b:String)
		{
			a = (displayLanguages.exists(a) ? displayLanguages.get(a) : a).toLowerCase();
			b = (displayLanguages.exists(b) ? displayLanguages.get(b) : b).toLowerCase();
			if (a < b)
				return -1;
			else if (a > b)
				return 1;
			return 0;
		});

		// 默认选中 en-US
		curSelected = languages.indexOf('en-US');
		if (curSelected < 0)
			curSelected = 0;

		// 标题 "Language / 语言"
		titleText = new FlxText(0, 0, FlxG.width, 'Language / 語言');
		titleText.setFormat(Alphabet.CJK_FONT_PATH, 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.y = FlxG.height * 0.3 - titleText.height - 20;
		titleText.alpha = 0;
		add(titleText);

		// 箭头和语言名
		arrowLeft = new Alphabet(0, 0, '<', false);
		arrowLeft.alpha = 0;
		add(arrowLeft);

		arrowRight = new Alphabet(0, 0, '>', false);
		arrowRight.alpha = 0;
		add(arrowRight);

		langNameText = new Alphabet(0, 0, getCurrentLangName(), true);
		langNameText.alpha = 0;
		add(langNameText);

		updatePositions();

		// 淡入动画
		FlxTween.tween(titleText, {alpha: 1}, 0.4, {ease: FlxEase.quartOut});
		FlxTween.tween(arrowLeft, {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.15});
		FlxTween.tween(arrowRight, {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.15});
		FlxTween.tween(langNameText, {alpha: 1}, 0.4, {ease: FlxEase.quartOut, startDelay: 0.15});
	}

	function getCurrentLangName():String
	{
		var lang:String = languages[curSelected];
		return displayLanguages.exists(lang) ? displayLanguages.get(lang) : lang;
	}

	function updatePositions()
	{
		var langName:String = getCurrentLangName();
		var totalWidth:Float = arrowLeft.width + langNameText.width + arrowRight.width + 80;

		var centerX:Float = FlxG.width / 2;
		var startX:Float = centerX - totalWidth / 2;

		arrowLeft.setPosition(startX, FlxG.height * 0.3 + 40);
		langNameText.setPosition(startX + arrowLeft.width + 40, FlxG.height * 0.3 + 40);
		arrowRight.setPosition(startX + arrowLeft.width + langNameText.width + 80, FlxG.height * 0.3 + 40);
	}

	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, languages.length - 1);

		// 销毁旧文字，重建新文字（Alphabet 的 text setter 可能不可靠）
		remove(langNameText);
		langNameText.destroy();
		langNameText = new Alphabet(0, 0, getCurrentLangName(), true);
		langNameText.alpha = 1;
		add(langNameText);
		updatePositions();

		// 箭头弹跳效果
		FlxTween.cancelTweensOf(arrowLeft, ['scale']);
		FlxTween.cancelTweensOf(arrowRight, ['scale']);
		arrowLeft.scale.set(1.3, 1.3);
		arrowRight.scale.set(1.3, 1.3);
		FlxTween.tween(arrowLeft.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.quartOut});
		FlxTween.tween(arrowRight.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.quartOut});

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	var selected:Bool = false;
	var selectingLanguage:Bool = false;

	override function update(elapsed:Float)
	{
		if (selectingLanguage)
		{
			super.update(elapsed);
			return;
		}

		super.update(elapsed);

		if (selected)
			return;

		if (controls.UI_LEFT_P)
			changeSelection(-1);
		if (controls.UI_RIGHT_P)
			changeSelection(1);

		if (FlxG.mouse.wheel != 0)
			changeSelection(FlxG.mouse.wheel > 0 ? 1 : -1);

		if (controls.ACCEPT)
		{
			selected = true;
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);

			// 淡出动画
			FlxTween.tween(titleText, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
			FlxTween.tween(arrowLeft, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
			FlxTween.tween(arrowRight, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
			FlxTween.tween(langNameText, {alpha: 0}, 0.3, {
				ease: FlxEase.quartIn,
				onComplete: function(_)
				{
					selectingLanguage = true;
					ClientPrefs.data.language = languages[curSelected];
					ClientPrefs.data.firstLaunch = false;
					ClientPrefs.saveSettings();
					Language.reloadPhrases();

					// 重置状态以应用新语言
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					MusicBeatState.resetState();
				}
			});
		}
	}
	#end
}