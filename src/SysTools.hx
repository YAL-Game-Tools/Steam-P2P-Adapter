package ;
import haxe.CallStack;
import haxe.Rest;

/**
 * ...
 * @author YellowAfterlife
 */
class SysTools {
	public static inline function print(text:String) {
		Sys.print(text);
	}
	public static inline function println(line:String) {
		Sys.println(line);
	}
	public static function printlns(lines:Rest<String>) {
		for (line in lines) Sys.println(line);
	}
	public static inline function printError(label:String, e:Dynamic) {
		println(label + ": " + e
			+ "\n" + CallStack.toString(CallStack.exceptionStack(true))
		);
	}
	public static function exit(?error:String):Any {
		if (error != null) Sys.println(error);
		Sys.println("Press any key to exit!");
		Sys.getChar(false);
		Sys.exit(error != null ? 1 : 0);
		return null;
	}
	public static function gets(prompt:String, def:String = ""):String {
		Sys.print(prompt);
		if (def != null && def != "") {
			Sys.print(' (default: `$def`)');
		}
		Sys.print('?: ');
		var s = Sys.stdin().readLine();
		if (s == "") s = def;
		return s;
	}
	public static function geti(prompt:String, def:Int = -1):Int {
		print(prompt);
		print(' (default: `$def`)');
		print('?: ');
		var i = Std.parseInt(Sys.stdin().readLine());
		if (i == null) i = def;
		return i;
	}
	public static function getm(prompt:String, opts:Array<String>):Int {
		println(prompt);
		for (i => opt in opts) {
			println('${i + 1} $opt');
		}
		print("> ");
		var c = Sys.getChar(true);
		println("");
		if (c >= "1".code && c < "1".code + opts.length) {
			return c - "1".code;
		} else return -1;
	}
}