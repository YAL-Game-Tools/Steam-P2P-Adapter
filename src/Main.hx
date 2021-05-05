package;

import haxe.io.Path;
import steamwrap.api.Steam;
import sys.FileSystem;
import sys.io.File;
import SysTools.*;

/**
 * ...
 * @author YellowAfterlife
 */
class Main {
	static function main() {
		println("hello!");
		Params.init();
		var appid_path = Path.directory(Sys.programPath()) + "/steam_appid.txt";
		if (!FileSystem.exists(appid_path)) {
			exit("Please create a steam_appid.txt and supply the ID of application inside.");
		}
		var appid_str = File.getContent(appid_path);
		var appid = Std.parseInt(appid_str);
		if (appid == null) exit('`$appid_str` is not a valid ID');
		println('Initializing Steam with appid=$appid...');
		Steam.init(appid);
		if (Steam.wantQuit) exit("That didn't work out!");
		//
		for (i in 0 ... 5) {
			Steam.onEnterFrame();
			Sys.sleep(0.1);
		}
		//
		var m = Params.mode;
		if (m < 0) m = getm("What would you like to do?", [
			"Server",
			"Client",
		]);
		switch (m) {
			case 0: Server.main();
			case 1: Client.main();
			default: exit("See you later then");
		}
		exit("Bye!");
	}
	
}