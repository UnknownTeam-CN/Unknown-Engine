package backend;

class RatingUtil
{
	/**
	 * 生成 Letter Rank 字符串
	 * @param accuracyPercent  0-100 的百分比精度
	 * @param misses          miss 数量
	 * @param bads            bad 数量
	 * @param goods           good 数量
	 * @param sicks           sick 数量
	 * @param shits           shit 数量
	 * @return Letter Rank 字符串，如 "(MFC) AAAAA"
	 */
	public static function generateLetterRank(accuracyPercent:Float, ?misses:Int = 0, ?bads:Int = 0, ?goods:Int = 0, ?sicks:Int = 0, ?shits:Int = 0):String
	{
		var ranking:String = "N/A";
		if (accuracyPercent <= 0) return "N/A";

		// FC 类型前缀（从最高到最低判断）
		if (misses == 0 && bads == 0 && shits == 0 && goods == 0)
			ranking = "(MFC)";  // Marvelous Full Combo（只有 sick）
		else if (misses == 0 && bads == 0 && shits == 0)
			ranking = "(GFC)";  // Good Full Combo（sick + good，无 bad/shit）
		else if (misses == 0)
			ranking = "(FC)";   // Full Combo
		else if (misses < 10)
			ranking = "(SDCB)"; // Single Digit Combo Breaks
		else
			ranking = "(Clear)";

		// WIFE 精度等级
		var wifeGrades:Array<String> = [
			"AAAAAA",
			"AAAAA:",
			"AAAA:",
			"AAAA",
			"AAA:",
			"AAA.",
			"AAA",
			"AA:",
			"AA.",
			"AA",
			"A:",
			"A.",
			"A",
			"B",
			"C",
			"D"
		];
		var wifeThreshold:Array<Float> = [
			99.9935, 99.980, 99.970, 99.955, 99.90,
			99.80, 99.70, 99.00, 96.50, 93.00,
			90.00, 85.00, 80.00, 70.00, 60.00, 0.00
		];

		for (i in 0...wifeGrades.length)
		{
			if (accuracyPercent >= wifeThreshold[i])
			{
				ranking = ranking + " " + wifeGrades[i];
				break;
			}
		}
		return ranking;
	}
}
