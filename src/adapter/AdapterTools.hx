package adapter;
import adapter.Adapter;
import steamwrap.api.SteamID;

/**
 * ...
 * @author YellowAfterlife
 */
class AdapterTools {
	@:noUsing public static function create(remote:SteamID, flags:Int):Adapter {
		switch (flags) {
			case 1: return new TcpAdapter(remote);
			case 2: return new UdpAdapter(remote);
			default: throw "Can't create an adapter for flags=" + flags;
		}
	}
}