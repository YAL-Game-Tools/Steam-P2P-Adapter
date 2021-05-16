package adapter;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import steamwrap.api.Steam;
import steamwrap.api.SteamID;
import SysTools.*;

/**
 * ...
 * @author YellowAfterlife
 */
class Adapter {
	public var remote:SteamID;
	public var hasError:Bool = false;
	
	public function new(remote:SteamID) {
		this.remote = remote;
	}
	
	public function readFromSocket(fn:Bytes->Void):Void {
		throw "todo";
	}
	public function writeToSocket(bytes:Bytes, pos:Int, len:Int):Bool {
		throw "todo";
	}
	public function closeSocket():Void {
		
	}
	
	public function writeToSteam(bytes:Bytes):Void {
		throw "todo";
	}
	
	function handleSteamPacketData(bytes:Bytes, pos:Int, len:Int, ?chunked:Bool):Bool {
		if (Params.logBytes) {
			print("steam -> " + len + "B -> socket");
			if (chunked) print(" [chunked]");
			var maxLogBytes = Params.maxLogBytes;
			var n = len > maxLogBytes ? maxLogBytes : len;
			for (i in 0 ... n) {
				print(" " + StringTools.hex(bytes.get(pos + i), 2));
			}
			println("");
		}
		
		return writeToSocket(bytes, pos, len);
	}
	
	var chunkBuilder:BytesBuffer = null;
	function handleSteamPacket():Bool {
		var bytes = Steam.networking.getPacketData();
		var len = bytes.length;
		if (len == 0) return true;
		var kind = bytes.get(0);
		if (Params.logPackets) print('steam -> ${len}B[$kind] -> ');
		
		switch (kind) {
			case Packet.Data:
				if (Params.logPackets) println("socket");
				if (!handleSteamPacketData(bytes, 5, len - 5)) return false;
			case Packet.ChunkStart:
				if (Params.logPackets) println("chunkStart");
				chunkBuilder = new BytesBuffer();
				chunkBuilder.addBytes(bytes, 1, len - 1);
				//println("chunk start: " + (len - 1));
			case Packet.ChunkPart:
				if (Params.logPackets) println("chunkPart");
				//println("chunk part: " + (len - 1));
				chunkBuilder.addBytes(bytes, 1, len - 1);
			case Packet.ChunkEnd:
				if (Params.logPackets) println("chunkEnd");
				chunkBuilder.addBytes(bytes, 1, len - 1);
				var cl = chunkBuilder.length;
				var cb = chunkBuilder.getBytes();
				//println("chunk end: " + (len - 1) + ', $cl total');
				if (!handleSteamPacketData(cb, 0, cl, true)) return false;
				chunkBuilder = null;
			case Packet.Disconnect:
				if (Params.logPackets) println("bye!");
				hasError = true;
				closeSocket();
				return false;
			case Packet.KeepAlive:
				if (Params.logPackets) println("poke");
			default:
				if (Params.logPackets) println("???");
		}
		return true;
	}
	
	public function update():Void {
		//Steam.onEnterFrame(); // not necessary - no events at this point
		SteamTools.keepAlive(remote);
		
		readFromSocket(function(bytes:Bytes) {
			writeToSteam(bytes);
		});
		if (hasError) return;
		
		while (Steam.networking.receivePacket()) {
			if (Steam.networking.getPacketSender() != remote) continue;
			
			if (!handleSteamPacket()) break;
		}
	}
	public function updateUntilError():Void {
		while (Steam.matchmaking.getLobbyID() != SteamID.defValue) {
			Sys.sleep(0.01);
			update();
			if (hasError) break;
		}
	}
}