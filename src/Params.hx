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
	
	public static var logPackets:Bool = false;
	public static var logBytes:Bool = false;
	public static var maxLogBytes = 16;
	public static var udpTimeout = 15.;
	public static var pollTimeout = 0.0001;
	
	/** 1: TCP, 2: UDP */
	public static var protocolFlags:Int = 0;
	
	static function parseInt(s:String):Int {
		var i = Std.parseInt(s);
		if (i == null) {
			SysTools.exit('Expected an integer, got `$s`');
			return -1;
		} else return i;
	}
	static function parseFloat(s:String):Float {
		var f = Std.parseFloat(s);
		if (Math.isNaN(f)) {
			SysTools.exit('Expected an number, got `$s`');
			return 0;
		} else return f;
	}
	
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
				case "--port": port = parseInt(arg(1)); 2;
				case "--tcp": protocolFlags |= 1; 1;
				case "--udp": protocolFlags |= 2; 1;
				case "--log-packets": logPackets = true; 1;
				case "--log-data": logBytes = true; 1;
				case "--udp-timeout": udpTimeout = parseFloat(arg(1)); 2;
				case "--poll-timeout": pollTimeout = parseFloat(arg(1)); 2;
				default: 0;
			}
			if (del > 0) {
				args.splice(i, del);
			} else i++;
		}
		Params.args = args;
	}
}