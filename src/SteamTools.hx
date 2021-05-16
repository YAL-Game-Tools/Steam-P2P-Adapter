package ;
import haxe.io.Bytes;
import steamwrap.api.Networking.EP2PSend;
import steamwrap.api.Steam;
import steamwrap.api.SteamID;

/**
 * ...
 * @author YellowAfterlife
 */
class SteamTools {
	public static var skipInputs = false;
	
	public static inline function waitFor(fn:Void->Bool, t:Float = 0.1) {
		Steam.onEnterFrame();
		while (!fn()) {
			Sys.sleep(t);
			Steam.onEnterFrame();
		}
	}
	public static function discardPackets() {
		while (Steam.networking.receivePacket()) {}
	}
	public static function init() {
		Steam.networking.whenP2PSessionRequested = function(e) {
			Steam.networking.acceptP2PSessionWithUser(e.remoteID);
		}
	}
	
	public static function sendSimple(remote:SteamID, pkt:Packet, type:EP2PSend = EP2PSend.RELIABLE) {
		var b = Bytes.alloc(1);
		b.set(0, pkt);
		if (!Steam.networking.sendPacket(remote, b, 1, type)) {
			Sys.println('Failed to send a simple packet ($pkt)');
		}
	}
	
	static var keepAlive_time:Float = 0;
	public static function keepAlive(remote:SteamID) {
		var t = Date.now().getTime();
		if (t < keepAlive_time) return;
		keepAlive_time = t + 5000;
		sendSimple(remote, Packet.KeepAlive);
	}
}