package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import backend.Highscore;
import backend.RatingUtil;
import backend.Song;
import backend.Conductor;
import objects.HitGraph;
import states.PlayState;

class ResultsScreen extends MusicBeatState
{
	var background:FlxSprite;
	var titleText:FlxText;
	var resultText:FlxText;
	var graphContainer:FlxSprite;
	var hitGraph:HitGraph;
	var graphBG:FlxSprite;

	var pressEnterText:FlxText;
	var replayHintText:FlxText;
	var songTitleText:FlxText;
	var scoreText:FlxText;
	var accuracyText:FlxText;
	var rankText:FlxText;
	var msWindowText:FlxText;

	var sicks:Int = 0;
	var goods:Int = 0;
	var bads:Int = 0;
	var shits:Int = 0;
	var songMisses:Int = 0;
	var highestCombo:Int = 0;
	var songScore:Int = 0;
	var accuracy:Float = 0;
	var ratingFC:String = "";
	var letterRank:String = "";

	var music:FlxSound;

	// 分数打乱动画
	var scoreScrambleText:FlxText;
	var scrambleTimer:Float = 1.5;
	var scrambleDone:Bool = false;
	var elementsRevealed:Bool = false;

	// 彩虹标题
	var rainbowHue:Float = 0;

	override function create()
	{
		super.create();

		// 获取 PlayState 的数据（从静态 resultsData） — Unknown Engine
		if (PlayState.resultsData != null)
		{
			var rd = PlayState.resultsData;
			sicks = rd.sicks;
			goods = rd.goods;
			bads = rd.bads;
			shits = rd.shits;
			songMisses = rd.misses;
			highestCombo = rd.highestCombo;
			songScore = rd.score;
			accuracy = rd.accuracy;
			ratingFC = rd.ratingFC;
		}
		else
		{
			// Fallback: 尝试从 instance 获取
			if (PlayState.instance != null)
			{
				sicks = PlayState.instance.ratingsData[0].hits;
				goods = PlayState.instance.ratingsData[1].hits;
				bads = PlayState.instance.ratingsData[2].hits;
				shits = PlayState.instance.ratingsData[3].hits;
				songMisses = PlayState.instance.songMisses;
				highestCombo = PlayState.instance.highestCombo;
				songScore = PlayState.instance.songScore;
				ratingFC = PlayState.instance.ratingFC;
				// 计算 accuracy
				var totalPlayed:Int = 0;
				var totalNotesHit:Float = 0;
				for (rating in PlayState.instance.ratingsData)
				{
					totalPlayed += rating.hits;
					totalNotesHit += rating.hits * rating.ratingMod;
				}
				totalPlayed += songMisses;
				if (totalPlayed > 0)
					accuracy = Math.min(1, totalNotesHit / totalPlayed);
			}
		}

		// 计算 Letter Rank — Unknown Engine
		letterRank = RatingUtil.generateLetterRank(accuracy * 100, songMisses, bads, goods, sicks, shits);

		// 背景
		background = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		background.alpha = 0;
		add(background);

		// 标题 — 直接定位，无入场动画（彩虹效果在 update 中处理）
		titleText = new FlxText(20, 20, 0, PlayState.isStoryMode ? Language.getPhrase('results_week_cleared', 'Week Cleared!') : Language.getPhrase('results_song_cleared', 'Song Cleared!'), 42);
		titleText.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.scrollFactor.set();
		add(titleText);

		// 分数打乱文字 — 居中大字
		scoreScrambleText = new FlxText(0, FlxG.height / 2 - 80, FlxG.width, '0', 64);
		scoreScrambleText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreScrambleText.scrollFactor.set();
		add(scoreScrambleText);

		// 歌曲名称 — 先隐藏，打乱结束后显示
		var songName:String = PlayState.SONG != null ? PlayState.SONG.song : "Unknown";
		songTitleText = new FlxText(20, 60, 0, songName, 32);
		songTitleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.GRAY, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songTitleText.scrollFactor.set();
		songTitleText.alpha = 0;
		add(songTitleText);

		// 成绩文字（左列）— 先隐藏
		var judgementStr:String = Language.getPhrase('results_judgements', 'Judgements:') + '\n'
			+ Language.getPhrase('results_sicks', 'Sicks: {1}', [sicks]) + '\n'
			+ Language.getPhrase('results_goods', 'Goods: {1}', [goods]) + '\n'
			+ Language.getPhrase('results_bads', 'Bads: {1}', [bads]) + '\n'
			+ Language.getPhrase('results_shits', 'Shits: {1}', [shits]) + '\n\n'
			+ Language.getPhrase('results_combo_breaks', 'Combo Breaks: {1}', [songMisses]) + '\n'
			+ Language.getPhrase('results_highest_combo', 'Highest Combo: {1}', [highestCombo]) + '\n'
			+ Language.getPhrase('results_score', 'Score: {1}', [songScore]) + '\n'
			+ Language.getPhrase('results_accuracy', 'Accuracy: {1}%', [CoolUtil.floorDecimal(accuracy * 100, 2)]) + '\n\n'
			+ Language.getPhrase('results_letter_rank', 'Letter Rank:') + '\n$letterRank';

		resultText = new FlxText(20, 110, 600, judgementStr, 28);
		resultText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		resultText.scrollFactor.set();
		resultText.alpha = 0;
		add(resultText);

		// 右侧 HitGraph 容器 — 先隐藏
		graphBG = new FlxSprite(FlxG.width - 520, 40).makeGraphic(500, 280, FlxColor.BLACK);
		graphBG.alpha = 0;
		graphBG.scrollFactor.set();
		add(graphBG);

		hitGraph = new HitGraph(FlxG.width - 510, 50, 490, 270);
		hitGraph.alpha = 0;
		hitGraph.scrollFactor.set();
		add(hitGraph);

		// 从 resultsData 传入 songLength，避免 PlayState.instance 已销毁时取到 0
		if (PlayState.resultsData != null && PlayState.resultsData.songLength > 0)
			hitGraph.songLength = PlayState.resultsData.songLength;

		// 构建 HitGraph 数据
		for (d in PlayState.beatHitData)
		{
			hitGraph.addToHistory(d[0], d[1], d[2]);
		}
		hitGraph.updateGraph();

		// 判定窗口 ms 显示 — 先隐藏
		var sickWin:Float = 45.0;
		var goodWin:Float = 90.0;
		var badWin:Float = 135.0;
		var shitWin:Float = 180.0;
		if (PlayState.instance != null && PlayState.instance.ratingsData != null)
		{
			if (PlayState.instance.ratingsData.length > 0)
				sickWin = PlayState.instance.ratingsData[0].hitWindow;
			if (PlayState.instance.ratingsData.length > 1)
				goodWin = PlayState.instance.ratingsData[1].hitWindow;
			if (PlayState.instance.ratingsData.length > 2)
				badWin = PlayState.instance.ratingsData[2].hitWindow;
			if (PlayState.instance.ratingsData.length > 3)
				shitWin = PlayState.instance.ratingsData[3].hitWindow;
		}

		var msStr:String = Language.getPhrase('results_time_windows', '±{1}ms | ±{2}ms | ±{3}ms').replace('{1}', Std.string(Math.floor(sickWin))).replace('{2}', Std.string(Math.floor(goodWin))).replace('{3}', Std.string(Math.floor(badWin)));
		msWindowText = new FlxText(0, 0, 0, msStr, 36);
		msWindowText.setFormat(Paths.font("vcr.ttf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		msWindowText.scrollFactor.set();
		msWindowText.screenCenter(Y);
		msWindowText.x = FlxG.width - 260;
		msWindowText.alpha = 0;
		add(msWindowText);

		// 底部提示 — 先隐藏
		pressEnterText = new FlxText(FlxG.width - 420, FlxG.height + 50, 0, Language.getPhrase('results_press_enter', 'Press ENTER to continue.'), 28);
		pressEnterText.setFormat(Paths.font("vcr.ttf"), 28, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		pressEnterText.scrollFactor.set();
		pressEnterText.alpha = 0;
		add(pressEnterText);

		// F1 回放提示 — 先隐藏
		if (!PlayState.loadRep && PlayState.rep != null)
		{
			replayHintText = new FlxText(FlxG.width - 420, FlxG.height + 60, 0, Language.getPhrase('results_press_f1_replay', 'Press F1 to Watch Replay'), 20);
			replayHintText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.GRAY, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			replayHintText.scrollFactor.set();
			replayHintText.alpha = 0;
			add(replayHintText);
		}

		// 背景淡入
		FlxTween.tween(background, {alpha: 0.5}, 0.5);

		// 背景音乐
		music = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		if (music != null)
		{
			music.volume = 0;
			music.play(false, FlxG.random.int(0, Std.int(music.length / 2)));
			FlxG.sound.list.add(music);
		}

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// 彩虹渐变色标题 — 连续色相循环
		rainbowHue = (rainbowHue + 120 * elapsed) % 360;
		titleText.color = FlxColor.fromHSB(rainbowHue, 1.0, 1.0);

		// 分数打乱动画
		if (!scrambleDone)
		{
			scrambleTimer -= elapsed;
			if (scrambleTimer <= 0)
			{
				// 打乱结束，显示真实分数
				scrambleDone = true;
				scoreScrambleText.text = '$songScore';
				scoreScrambleText.color = FlxColor.LIME;
				FlxTween.tween(scoreScrambleText, {alpha: 0}, 0.4, {startDelay: 0.6});
			}
			else
			{
				// 越接近结束越快跳
				var speed:Float = scrambleTimer / 1.5;
				if (FlxG.random.float(0, 1) < 0.4 + speed * 0.6)
				{
					var rndScore:Int = FlxG.random.int(0, songScore + Std.int(songScore * speed));
					scoreScrambleText.text = '$rndScore';
				}
			}
		}

		// 打乱结束后渐入其他元素
		if (scrambleDone && !elementsRevealed)
		{
			elementsRevealed = true;
			FlxTween.tween(songTitleText, {alpha: 1}, 0.4);
			FlxTween.tween(resultText, {alpha: 1, y: 110}, 0.5, {ease: FlxEase.expoOut});
			FlxTween.tween(graphBG, {alpha: 0.6}, 0.5);
			FlxTween.tween(hitGraph, {alpha: 1}, 0.5, {startDelay: 0.2});
			FlxTween.tween(msWindowText, {alpha: 1}, 0.5, {startDelay: 0.3});
			FlxTween.tween(pressEnterText, {alpha: 1, y: FlxG.height - 50}, 0.5, {ease: FlxEase.expoOut});
			if (replayHintText != null)
				FlxTween.tween(replayHintText, {alpha: 1, y: FlxG.height - 80}, 0.5, {ease: FlxEase.expoOut});
		}

		// 背景音乐淡入
		if (music != null && music.volume < 0.5)
			music.volume += 0.01 * elapsed;

		if (controls.ACCEPT || controls.BACK)
		{
			if (!scrambleDone) return; // 打乱期间禁止跳过
			if (music != null) music.fadeOut(0.3);

			// 保存最高分
			Highscore.saveScore(Song.loadedSongName, songScore, PlayState.storyDifficulty, accuracy);

			// 清理 replay
			PlayState.loadRep = false;
			PlayState.rep = null;
			PlayState.beatHitData = [];
			PlayState.resultsData = null;

			if (PlayState.isStoryMode)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				Conductor.bpm = 102;
				MusicBeatState.switchState(new MainMenuState());
			}
			else
			{
				MusicBeatState.switchState(new FreeplayState());
			}
		}

		// F1 回放
		if (FlxG.keys.justPressed.F1 && !PlayState.loadRep)
		{
			Highscore.saveScore(Song.loadedSongName, songScore, PlayState.storyDifficulty, accuracy);

			if (music != null) music.fadeOut(0.3);

			PlayState.isStoryMode = false;
			PlayState.loadRep = true; // 启用回放模式
			LoadingState.loadAndSwitchState(new PlayState());
		}
	}
}
