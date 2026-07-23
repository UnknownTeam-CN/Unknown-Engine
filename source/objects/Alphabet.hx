package objects;

enum Alignment
{
	LEFT;
	CENTERED;
	RIGHT;
}

class Alphabet extends FlxSpriteGroup
{
	// 字体配置 - 使用 game_font.ttf (位于 assets/fonts/game_font.ttf)
	public static var GAME_FONT_PATH:String = Paths.font("game_font.ttf");
	public static var BASE_SIZE:Int = 48;

	// CJK 字体路径 — 用于中/日/韩文字渲染
	// 优先 simhei(黑体)，备选 NotoSansSC(思源黑体)，均不可用则回退 game_font
	public static var CJK_FONT_PATH:String = getCJKFontPath();
	public var useCJKFont:Bool = false;

	static function getCJKFontPath():String
	{
		#if sys
		if (sys.FileSystem.exists("C:/Windows/Fonts/simhei.ttf"))
			return "C:/Windows/Fonts/simhei.ttf";
		if (sys.FileSystem.exists("C:/Windows/Fonts/NotoSansSC-VF.ttf"))
			return "C:/Windows/Fonts/NotoSansSC-VF.ttf";
		#end
		return GAME_FONT_PATH;
	}

	public var text(default, set):String;

	public var bold:Bool = false;
	public var letters:Array<AlphaCharacter> = [];

	public var isMenuItem:Bool = false;
	public var targetY:Int = 0;
	public var changeX:Bool = true;
	public var changeY:Bool = true;

	public var alignment(default, set):Alignment = LEFT;
	public var scaleX(default, set):Float = 1;
	public var scaleY(default, set):Float = 1;
	public var rows:Int = 0;

	public var distancePerItem:FlxPoint = new FlxPoint(20, 120);
	public var startPosition:FlxPoint = new FlxPoint(0, 0);

	// 字间距控制
	public var letterSpacing:Float = 0;

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = true)
	{
		super(x, y);

		this.startPosition.x = x;
		this.startPosition.y = y;
		this.bold = bold;
		this.text = text;
	}

	public function setAlignmentFromString(align:String)
	{
		switch(align.toLowerCase().trim())
		{
			case 'right':
				alignment = RIGHT;
			case 'center' | 'centered':
				alignment = CENTERED;
			default:
				alignment = LEFT;
		}
	}

	private function set_alignment(align:Alignment)
	{
		alignment = align;
		updateAlignment();
		return align;
	}

	private function updateAlignment()
	{
		for (letter in letters)
		{
			var newOffset:Float = 0;
			switch(alignment)
			{
				case CENTERED:
					newOffset = letter.rowWidth / 2;
				case RIGHT:
					newOffset = letter.rowWidth;
				default:
					newOffset = 0;
			}

			letter.offset.x -= letter.alignOffset;
			letter.alignOffset = newOffset * scale.x;
			letter.offset.x += letter.alignOffset;
		}
	}

	private function set_text(newText:String)
	{
		newText = newText.replace('\\n', '\n');
		clearLetters();
		createLetters(newText);
		updateAlignment();
		this.text = newText;
		return newText;
	}

	public function clearLetters()
	{
		var i:Int = letters.length;
		while (i > 0)
		{
			--i;
			var letter:AlphaCharacter = letters[i];
			if(letter != null)
			{
				letter.kill();
				letters.remove(letter);
				remove(letter);
			}
		}
		letters = [];
		rows = 0;
	}

	public function setScale(newX:Float, newY:Null<Float> = null)
	{
		var lastX:Float = scale.x;
		var lastY:Float = scale.y;
		if(newY == null) newY = newX;
		@bypassAccessor
			scaleX = newX;
		@bypassAccessor
			scaleY = newY;

		scale.x = newX;
		scale.y = newY;
		softReloadLetters(newX / lastX, newY / lastY);
	}

	private function set_scaleX(value:Float)
	{
		if (value == scaleX) return value;

		var ratio:Float = value / scale.x;
		scale.x = value;
		scaleX = value;
		softReloadLetters(ratio, 1);
		return value;
	}

	private function set_scaleY(value:Float)
	{
		if (value == scaleY) return value;

		var ratio:Float = value / scale.y;
		scale.y = value;
		scaleY = value;
		softReloadLetters(1, ratio);
		return value;
	}

	public function softReloadLetters(ratioX:Float = 1, ratioY:Null<Float> = null)
	{
		if(ratioY == null) ratioY = ratioX;

		for (letter in letters)
		{
			if(letter != null)
			{
				letter.setupAlphaCharacter(
					(letter.x - x) * ratioX + x,
					(letter.y - y) * ratioY + y
				);
			}
		}
	}

	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var lerpVal:Float = Math.exp(-elapsed * 9.6);
			if(changeX)
				x = FlxMath.lerp((targetY * distancePerItem.x) + startPosition.x, x, lerpVal);
			if(changeY)
				y = FlxMath.lerp((targetY * 1.3 * distancePerItem.y) + startPosition.y, y, lerpVal);
		}
		super.update(elapsed);
	}

	public function snapToPosition()
	{
		if (isMenuItem)
		{
			if(changeX)
				x = (targetY * distancePerItem.x) + startPosition.x;
			if(changeY)
				y = (targetY * 1.3 * distancePerItem.y) + startPosition.y;
		}
	}

	private static var Y_PER_ROW:Float = 85;

	private function createLetters(newText:String)
	{
		var consecutiveSpaces:Int = 0;

		var xPos:Float = 0;
		var rowData:Array<Float> = [];
		rows = 0;

		// 空格宽度
		var spaceWidth:Float = getSpaceWidth();

		// 预扫描: 检测是否包含 CJK 字符，决定字体
		useCJKFont = false;
		for (i in 0...newText.length)
		{
			if (AlphaCharacter.isCJKChar(newText.charAt(i)))
			{
				useCJKFont = true;
				break;
			}
		}

		for (i in 0...newText.length)
		{
			var character:String = newText.charAt(i);
			if(character != '\n')
			{
				var spaceChar:Bool = (character == " " || (bold && character == "_"));
				if (spaceChar) consecutiveSpaces++;

				var isAlphabet:Bool = AlphaCharacter.isTypeAlphabet(character.toLowerCase());
				if ((AlphaCharacter.allLetters.exists(character.toLowerCase()) || AlphaCharacter.isCJKChar(character)) && (!bold || !spaceChar))
				{
					if (consecutiveSpaces > 0)
					{
						xPos += spaceWidth * consecutiveSpaces * scaleX;
						rowData[rows] = xPos;
						if(!bold && xPos >= FlxG.width * 0.65)
						{
							xPos = 0;
							rows++;
						}
					}
					consecutiveSpaces = 0;

					var letter:AlphaCharacter = cast recycle(AlphaCharacter, true);
					letter.scale.x = scaleX;
					letter.scale.y = scaleY;
					letter.rowWidth = 0;

					letter.setupAlphaCharacter(xPos, rows * Y_PER_ROW * scale.y, character, bold);
					@:privateAccess letter.parent = this;

					letter.row = rows;

					// 使用字体的实际宽度作为间距，包含字间距（letterSpacing 不乘 scale，保持实际像素值）
					var letterWidth:Float = letter.width > 0 ? letter.width : spaceWidth;
					xPos += letterWidth + letterSpacing + (letter.letterOffset[0]) * scale.x;
					rowData[rows] = xPos;

					add(letter);
					letters.push(letter);
				}
			}
			else
			{
				xPos = 0;
				rows++;
			}
		}

		for (letter in letters)
		{
			letter.rowWidth = rowData[letter.row] / scale.x;
		}

		if(letters.length > 0) rows++;
	}

	private function getSpaceWidth():Float
	{
		// 使用字体中空格的宽度，默认约为 BASE_SIZE * 0.4
		return BASE_SIZE * 0.4;
	}
}


///////////////////////////////////////////
// ALPHABET LETTERS, SYMBOLS AND NUMBERS //
///////////////////////////////////////////

class AlphaCharacter extends FlxText
{
	// 允许的字符映射
	public static var allLetters:Map<String, Null<Dynamic>> = new Map();

	public static function initLetters():Void
	{
		// 初始化允许的字符
		var alphabet:String = "abcdefghijklmnopqrstuvwxyz";
		var numbers:String = "1234567890";
		var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!? ";

		var allChars:String = alphabet + alphabet.toUpperCase() + numbers + symbols;

		for (i in 0...allChars.length)
		{
			var c:String = allChars.charAt(i);
			allLetters.set(c, true);
		}

		// 确保 ? 存在
		allLetters.set('?', true);
	}

	// 确保静态初始化
	private static var _init = {
		initLetters();
		true;
	}

	var parent:Alphabet;
	public var alignOffset:Float = 0;
	public var letterOffset:Array<Float> = [0, 0];

	public var row:Int = 0;
	public var rowWidth:Float = 0;
	public var character:String = '?';

	// 跟踪当前字体，避免重复 setFormat 调用
	var _currentFont:String = null;

	// 兼容旧代码 - image 字段 (现在使用 TTF 字体，不再需要)
	public var image(default, set):String = '';

	private function set_image(name:String):String
	{
		image = name;
		return name;
	}

	// 兼容旧代码 - loadAlphabetData (现在使用 TTF 字体，不再需要)
	public static function loadAlphabetData(request:String = 'alphabet'):Void
	{
		// TTF 字体模式下不需要加载精灵图集数据
	}

	public function new()
	{
		// 初始化 FlxText - 使用 game_font.ttf
		super(0, 0);
		setFormat(Alphabet.GAME_FONT_PATH, Alphabet.BASE_SIZE, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK, true);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	public function setupAlphaCharacter(x:Float, y:Float, ?character:String = null, ?bold:Null<Bool> = null)
	{
		this.x = x;
		this.y = y;

		if(parent != null)
		{
			if(bold == null)
				bold = parent.bold;
			this.scale.x = parent.scaleX;
			this.scale.y = parent.scaleY;
		}

		if(character != null)
		{
			this.character = character;

			// 根据父 Alphabet 的 useCJKFont 标志自动切换字体
			var targetFont:String = (parent != null && parent.useCJKFont) ? Alphabet.CJK_FONT_PATH : Alphabet.GAME_FONT_PATH;

			if (_currentFont != targetFont)
			{
				setFormat(targetFont, Alphabet.BASE_SIZE, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK, true);
				_currentFont = targetFont;
				antialiasing = ClientPrefs.data.antialiasing;
			}

			// 设置文本为字符
			text = character;

			// 根据 bold 设置粗体
			// FlxText 的粗体通过 HTML 样式模拟
			updateHitbox();
		}
	}

	public static function isTypeAlphabet(c:String):Bool
	{
		var ascii = StringTools.fastCodeAt(c, 0);
		return (ascii >= 65 && ascii <= 90)
			|| (ascii >= 97 && ascii <= 122)
			|| (ascii >= 192 && ascii <= 214)
			|| (ascii >= 216 && ascii <= 246)
			|| (ascii >= 248 && ascii <= 255);
	}

	/**
	 * 判断是否为 CJK (中日韩) 字符
	 * 覆盖: CJK 统一表意文字、标点、全角字符、假名、谚文
	 */
	public static function isCJKChar(c:String):Bool
	{
		if (c == null || c.length == 0) return false;
		var code = StringTools.fastCodeAt(c, 0);
		return (code >= 0x4E00 && code <= 0x9FFF)       // CJK 统一表意文字 (常用汉字)
			|| (code >= 0x3400 && code <= 0x4DBF)        // CJK 扩展 A
			|| (code >= 0xF900 && code <= 0xFAFF)        // CJK 兼容表意文字
			|| (code >= 0x3000 && code <= 0x303F)        // CJK 标点符号 (。、〃 etc)
			|| (code >= 0xFF00 && code <= 0xFFEF)        // 全角字符 (！＂ etc)
			|| (code >= 0x3040 && code <= 0x309F)        // 平假名
			|| (code >= 0x30A0 && code <= 0x30FF)        // 片假名
			|| (code >= 0xAC00 && code <= 0xD7AF)        // 韩文音节
			|| (code >= 0x20000 && code <= 0x2A6DF);     // CJK 扩展 B (生僻字)
	}

	override public function updateHitbox()
	{
		super.updateHitbox();

		// 根据字符调整偏移量
		// 对于某些特殊字符可能需要微调
		letterOffset[0] = 0;
		letterOffset[1] = 0;
	}
}
