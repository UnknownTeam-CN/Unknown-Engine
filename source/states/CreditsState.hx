package states;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.ModernPanel;
import ui.ModernTheme;

/**
	CreditsState — two-pane layout with full mouse support:
	  left  : Team categories (clickable / wheel)
	  right : members of the selected team, scrolling when the list is long
	Mouse: hover/click to select; wheel scrolls; click a member to open its link.
	Keyboard: UP/DOWN member, LEFT/RIGHT team, ENTER link, ESC back.
 */
class CreditsState extends MusicBeatState
{
	var bg:FlxSprite;
	var overlay:FlxSprite;
	var intendedColor:FlxColor = 0;

	var categories:Array<String> = [];
	var categoryMembers:Array<Array<Int>> = [];
	var curCat:Int = 0;
	var curMember:Int = 0;

	var creditsStuff:Array<Array<String>> = [];

	var catTexts:Array<FlxText> = [];
	var memberNameTexts:Array<FlxText> = [];
	var memberRoleTexts:Array<FlxText> = [];
	var memberIcons:Array<FlxSprite> = [];
	var memberBar:FlxSprite;
	var memberScroll:Int = 0;

	var leftPanelRight:Float = 390; // right edge of the category panel
	var rightX:Float = 430;         // left edge of the member list content
	var rowStep:Float = 84;
	var rowTop:Float = 100;
	var hintText:FlxText;

	var timeNotMoving:Float = 0;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end
		super.create();
		persistentUpdate = true;

		bg = ui.FluidBackground.create();
		add(bg);

		overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, ModernTheme.OVERLAY);
		overlay.alpha = 0.22;
		overlay.scrollFactor.set();
		add(overlay);

		#if MODS_ALLOWED
		for (mod in Mods.parseList().enabled) pushModCreditsToList(mod);
		#end

		var defaultList:Array<Array<String>> = [ //Name - Icon name - Role - Link - BG Color
			["Unknown Engine Team"],
			["Pandaman",		 "pdm",		    "Programmer and Head of Unknown Engine",		 "https://space.bilibili.com/455118449", 		"444444"],
			["Charming", 	     "charming",    "Suggestions and Financial help", 				 "https://space.bilibili.com/2089923735",	    "85E2F4"],
			["The Original Engine's Members"],
			["Psych Engine Team"],
			["Shadow Mario",     "shadowmario", "Main Programmer and Head of Psych Engine",      "https://ko-fi.com/shadowmario", 				"444444"],
			["Riveren", 		 "riveren",     "Main Artist/Animator of Psych Engine",          "https://x.com/riverennn", 					"14967B"],
			["Former Engine Members"],
			["bb-panzu", 		 "bb",		    "Ex-Programmer of Psych Engine", 				 "https://x.com/bbsub3",					    "3E813A"],
			["Engine Contributors"],
			["crowplexus",		 "crowplexus", "Linux Support, HScript Iris, Input System v3, and Other PRs", "https://twitter.com/IamMorwen", "CFCFCF"],
			["Kamizeta", 		 "kamizeta", "Creator of Pessy, Psych Engine's mascot.", "https://www.instagram.com/cewweey/", "D21C11"],
			["MaxNeton", 		 "maxneton", "Loading Screen Easter Egg Artist/Animator.", "https://bsky.app/profile/maxneton.bsky.social", "3C2E4E"],
			["Keoiki", "keoiki", "Note Splash Animations and Latin Alphabet", "https://x.com/Keoiki_", "D2D2D2"],
			["SqirraRNG", "sqirra", "Crash Handler and Base code for\nChart Editor's Waveform", "https://x.com/gedehari", "E1843A"],
			["EliteMasterEric", "mastereric", "Runtime Shaders support and Other PRs", "https://x.com/EliteMasterEric", "FFBD40"],
			["MAJigsaw77", "majigsaw", ".MP4 Video Loader Library (hxvlc)", "https://x.com/MAJigsaw77", "5F5F5F"],
			["iFlicky", "flicky", "Composer of Psync and Tea Time\nAnd some sound effects", "https://x.com/flicky_i", "9E29CF"],
			["KadeDev", "kade", "Fixed some issues on Chart Editor and Other PRs", "https://x.com/kade0912", "64A250"],
			["superpowers04", "superpowers04", "LUA JIT Fork", "https://x.com/superpowers04", "B957ED"],
			["CheemsAndFriends", "cheems", "Creator of FlxAnimate", "https://x.com/CheemsnFriendos", "E1E1E1"],
			["Funkin' Crew"],
			["ninjamuffin99", "ninjamuffin99", "Programmer of Friday Night Funkin'", "https://x.com/ninja_muffin99", "CF2D2D"],
			["PhantomArcade", "phantomarcade", "Animator of Friday Night Funkin'", "https://x.com/PhantomArcade3K", "FADC45"],
			["evilsk8r", "evilsk8r", "Artist of Friday Night Funkin'", "https://x.com/evilsk8r", "5ABD4B"],
			["kawaisprite", "kawaisprite", "Composer of Friday Night Funkin'", "https://x.com/kawaisprite", "378FC7"]
		];
		for (i in defaultList)
			creditsStuff.push(i);

		buildCategories();

		// Left glass panel (categories)
		var leftPanel:ModernPanel = new ModernPanel(24, 24, 340, FlxG.height - 110);
		add(leftPanel);
		leftPanelRight = 24 + 340;

		var paneTitle:FlxText = new FlxText(44, 40, 300, Language.getPhrase('credits_teams', 'TEAMS'), 20);
		paneTitle.setFormat(Paths.font(ModernTheme.FONT), 20, ModernTheme.ACCENT, LEFT);
		paneTitle.scrollFactor.set();
		add(paneTitle);

		buildCategoryTexts();
		updateCategoryHighlight();

		// Right glass panel (members)
		var rightPanel:ModernPanel = new ModernPanel(rightX - 30, 24, FlxG.width - rightX - 6, FlxG.height - 110);
		rightPanel.alpha = 0.55;
		add(rightPanel);

		memberBar = new FlxSprite(rightX - 24, rowTop).makeGraphic(5, 52, ModernTheme.ACCENT);
		memberBar.scrollFactor.set();
		add(memberBar);

		hintText = new FlxText(24, FlxG.height - 30, FlxG.width - 48, Language.getPhrase('credits_hint', 'Click / Wheel to browse    ENTER / Click member to open link    ESC Back'), 16);
		hintText.setFormat(Paths.font('editor_font.ttf'), 16, ModernTheme.TEXT_DIM, RIGHT);
		hintText.scrollFactor.set();
		add(hintText);

		rebuildMembers();
		applyCategoryColor();
	}

	function buildCategories()
	{
		var curTitle:String = null;
		var curList:Array<Int> = [];
		function flush()
		{
			if (curTitle != null && curList.length > 0)
			{
				categories.push(curTitle);
				categoryMembers.push(curList);
			}
		}
		for (i => credit in creditsStuff)
		{
			if (credit.length <= 1)
			{
				var t:String = credit[0];
				if (t != null && t.trim().length > 0)
				{
					flush();
					curTitle = t;
					curList = [];
				}
				continue;
			}
			if (curTitle == null)
				curTitle = Language.getPhrase('credits_people', 'People');
			curList.push(i);
		}
		flush();
		if (categories.length == 0)
		{
			categories.push(Language.getPhrase('credits_people', 'People'));
			categoryMembers.push([for (i in 0...creditsStuff.length) i]);
		}
	}

	function buildCategoryTexts()
	{
		var yStart:Float = 96;
		var step:Float = Math.min(60, (FlxG.height - 190) / Math.max(1, categories.length));
		for (i => cat in categories)
		{
			var t:FlxText = new FlxText(44, yStart + i * step, 290, cat, 22);
			t.setFormat(Paths.font(ModernTheme.FONT), 22, ModernTheme.TEXT_MID, LEFT);
			t.scrollFactor.set();
			t.antialiasing = true;
			add(t);
			catTexts.push(t);
		}
	}

	function updateCategoryHighlight()
	{
		for (i => t in catTexts)
		{
			t.color = (i == curCat) ? ModernTheme.ACCENT : ModernTheme.TEXT_MID;
			t.alpha = (i == curCat) ? 1 : 0.75;
		}
	}

	function clearMembers()
	{
		for (t in memberNameTexts) { remove(t); t.destroy(); }
		for (t in memberRoleTexts) { remove(t); t.destroy(); }
		for (ic in memberIcons) { remove(ic); ic.destroy(); }
		memberNameTexts = [];
		memberRoleTexts = [];
		memberIcons = [];
		memberScroll = 0;
	}

	/** Number of member rows that fit in the right panel. */
	function visibleRows():Int
	{
		var avail:Float = FlxG.height - 150 - rowTop;
		return Std.int(Math.max(1, Math.floor(avail / rowStep)));
	}

	function rebuildMembers()
	{
		clearMembers();
		if (categories.length == 0 || curCat >= categories.length) return;
		if (curMember >= categoryMembers[curCat].length) curMember = 0;

		var list:Array<Int> = categoryMembers[curCat];
		for (idx => gIdx in list)
		{
			var credit:Array<String> = creditsStuff[gIdx];
			var icon:FlxSprite = createCreditIcon(credit);
			icon.scrollFactor.set();
			add(icon);
			memberIcons.push(icon);

			var nameTxt:FlxText = new FlxText(0, 0, FlxG.width - rightX - 90, credit[0], 28);
			nameTxt.setFormat(Paths.font(ModernTheme.FONT), 28, ModernTheme.TEXT_HI, LEFT);
			nameTxt.scrollFactor.set();
			nameTxt.antialiasing = true;
			add(nameTxt);
			memberNameTexts.push(nameTxt);

			var roleTxt:FlxText = new FlxText(0, 0, FlxG.width - rightX - 90, (credit[2] != null ? credit[2] : ''), 15);
			roleTxt.setFormat(Paths.font(ModernTheme.FONT_MONO), 15, ModernTheme.TEXT_MID, LEFT);
			roleTxt.scrollFactor.set();
			roleTxt.antialiasing = true;
			add(roleTxt);
			memberRoleTexts.push(roleTxt);
		}
		updateMemberView();
	}

	/** Position + color every visible member row, scrolling long lists. */
	function updateMemberView()
	{
		if (categories.length == 0 || curCat >= categories.length) return;
		var len:Int = categoryMembers[curCat].length;
		if (len == 0) return;
		if (curMember >= len) curMember = 0;

		// keep selection inside the visible window instead of shrinking rows
		var vis:Int = visibleRows();
		var maxScroll:Int = Std.int(Math.max(0, len - vis));
		memberScroll = Std.int(Math.max(0, Math.min(maxScroll, curMember)));
		if (curMember > memberScroll + vis - 1) memberScroll = curMember - vis + 1;
		if (memberScroll < 0) memberScroll = 0;

		for (i in 0...len)
		{
			var y:Float = rowTop + (i - memberScroll) * rowStep;
			var isSel:Bool = (i == curMember);
			var inView:Bool = (y > -rowStep && y < FlxG.height - 120);

			if (memberIcons[i] != null)
			{
				memberIcons[i].x = rightX;
				memberIcons[i].y = y;
				memberIcons[i].visible = inView;
			}
			// ttf baseline fix: center the name against the 48px icon row slot
			if (memberNameTexts[i] != null)
			{
				memberNameTexts[i].x = rightX + 62;
				memberNameTexts[i].y = y + 4;
				memberNameTexts[i].visible = inView;
				memberNameTexts[i].color = isSel ? ModernTheme.ACCENT : ModernTheme.TEXT_HI;
			}
			if (memberRoleTexts[i] != null)
			{
				memberRoleTexts[i].x = rightX + 62;
				memberRoleTexts[i].y = y + 36;
				memberRoleTexts[i].visible = inView;
				memberRoleTexts[i].color = isSel ? ModernTheme.TEXT_HI : ModernTheme.TEXT_MID;
			}
		}
		if (memberBar != null)
			memberBar.y = rowTop + (curMember - memberScroll) * rowStep + 14;
	}

	function createCreditIcon(credit:Array<String>):FlxSprite
	{
		var str:String = 'credits/missing_icon';
		if (credit[1] != null && credit[1].length > 0)
		{
			var fileName:String = 'credits/' + credit[1];
			if (Paths.fileExists('images/$fileName.png', IMAGE)) str = fileName;
			else if (Paths.fileExists('images/$fileName-pixel.png', IMAGE)) str = fileName + '-pixel';
		}
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(str));
		if (str.endsWith('-pixel')) spr.antialiasing = false;
		spr.setGraphicSize(48, 48);
		spr.updateHitbox();
		return spr;
	}

	function selectCategory(i:Int)
	{
		ui.FluidBackground.kick();
		if (i == curCat) return;
		curCat = i;
		curMember = 0;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		updateCategoryHighlight();
		rebuildMembers();
		applyCategoryColor();
	}

	function changeMember(change:Int)
	{
		ui.FluidBackground.kick();
		if (categories.length == 0 || curCat >= categories.length) return;
		var len:Int = categoryMembers[curCat].length;
		if (len == 0) return;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curMember = FlxMath.wrap(curMember + change, 0, len - 1);
		updateMemberView();
		applyCategoryColor();
	}

	function currentCredit():Array<String>
	{
		if (categories.length == 0 || curCat >= categories.length) return null;
		var list:Array<Int> = categoryMembers[curCat];
		if (list.length == 0) return null;
		return creditsStuff[list[curMember % list.length]];
	}

	function applyCategoryColor()
	{
		return; // fluid background already carries the theme palette; no per-member tint
		var credit:Array<String> = currentCredit();
		if (credit == null) return;
		var colHex:String = credit[4];
		var newColor:FlxColor = colHex != null && colHex.length > 0 ? CoolUtil.colorFromString(colHex) : FlxColor.fromRGB(30, 42, 58);
		if (newColor == intendedColor) return;
		intendedColor = newColor;
		FlxTween.cancelTweensOf(bg);
		FlxTween.color(bg, 1, bg.color, intendedColor);
	}

	function openSelectedLink()
	{
		var credit:Array<String> = currentCredit();
		if (credit == null) return;
		if (credit[3] != null && credit[3].length > 4)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			CoolUtil.browserLoad(credit[3]);
		}
		else FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		// ---- Mouse support ----
		if ((FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed)
		{
			FlxG.mouse.visible = true;
			timeNotMoving = 0;

			// hover a category -> switch team
			for (i => t in catTexts)
			{
				if (FlxG.mouse.overlaps(t) && curCat != i)
				{
					selectCategory(i);
					break;
				}
			}
			// hover a member row -> select it (scrolls into view)
			if (categories.length > 0 && curCat < categories.length)
			{
				var len:Int = categoryMembers[curCat].length;
				var hovered:Int = -1;
				for (i in 0...len)
				{
					var ry:Float = rowTop + (i - memberScroll) * rowStep;
					if (FlxG.mouse.x > rightX - 40 && FlxG.mouse.x < FlxG.width - 30
						&& FlxG.mouse.y > ry && FlxG.mouse.y < ry + rowStep)
					{
						hovered = i;
						break;
					}
				}
				if (hovered >= 0 && hovered != curMember)
				{
					curMember = hovered;
					updateMemberView();
					applyCategoryColor();
				}
			}
			// click a member -> open link; click empty area of member side -> nothing
			if (FlxG.mouse.justPressed)
			{
				if (FlxG.mouse.x > rightX - 40 && FlxG.mouse.x < FlxG.width - 30
					&& FlxG.mouse.y > rowTop && FlxG.mouse.y < FlxG.height - 120)
					openSelectedLink();
				else
				{
					var clickedCat:Int = -1;
					for (i => t in catTexts)
						if (FlxG.mouse.overlaps(t)) { clickedCat = i; break; }
					if (clickedCat >= 0) selectCategory(clickedCat);
				}
			}
		}
		else
		{
			timeNotMoving += elapsed;
			if (timeNotMoving > 2.5) FlxG.mouse.visible = false;
		}

		// wheel: over categories switches team, over members scrolls members
		if (FlxG.mouse.wheel != 0)
		{
			FlxG.mouse.visible = true;
			if (FlxG.mouse.x < leftPanelRight) selectCategory(FlxMath.wrap(curCat + (FlxG.mouse.wheel > 0 ? -1 : 1), 0, categories.length - 1));
			else changeMember(FlxG.mouse.wheel > 0 ? -1 : 1);
		}

		// ---- Keyboard ----
		if (controls.UI_UP_P) changeMember(-1);
		else if (controls.UI_DOWN_P) changeMember(1);

		if (controls.UI_LEFT_P) selectCategory(FlxMath.wrap(curCat - 1, 0, categories.length - 1));
		else if (controls.UI_RIGHT_P) selectCategory(FlxMath.wrap(curCat + 1, 0, categories.length - 1));

		if (controls.ACCEPT) openSelectedLink();
		else if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	#if MODS_ALLOWED
	function pushModCreditsToList(folder:String)
	{
		var creditsFile:String = Paths.mods(folder + '/data/credits.txt');
		#if TRANSLATIONS_ALLOWED
		var translatedCredits:String = Paths.mods(folder + '/data/credits-${ClientPrefs.data.language}.txt');
		#end

		if (#if TRANSLATIONS_ALLOWED (FileSystem.exists(translatedCredits) && (creditsFile = translatedCredits) == translatedCredits) || #end FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for (i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if (arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
	}
	#end
}
