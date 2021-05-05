package ;

/**
 * ...
 * @author YellowAfterlife
 */
class Params {
	public static var args:Array<String> = [];
	public static var mode:Int = -1;
	public static var host:String = null;
	public static var port:Int = -1;
	public static function init() {
		var i = 0;
		var args = Sys.args();
		while (i < args.length) {
			inline function arg(ofs:Int):String {
				return args[i + ofs];
			}
			var del = switch (args[i]) {
				case "--server": mode = 0; 1;
				case "--client": mode = 1; 1;
				case "--host": host = arg(1); 2;
				case "--port": port = Std.parseInt(arg(1)); 2;
				case "--log-packets": Adapter.logPackets = true; 1;
				case "--log-data": Adapter.logData = true; 1;
				default: 0;
			}
			if (del > 0) {
				args.splice(i, del);
			} else i++;
		}
		Params.args = args;
	}
}