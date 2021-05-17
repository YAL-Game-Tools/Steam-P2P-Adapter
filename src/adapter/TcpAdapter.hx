package adapter;
import haxe.io.Bytes;
import steamwrap.api.Networking.EP2PSend;
import steamwrap.api.Steam;
import steamwrap.api.SteamID;
import sys.net.Host;
import sys.net.Socket;
import SysTools.*;
using BytesTools;

/**
 * ...
 * @author YellowAfterlife
 */
class TcpAdapter extends Adapter {
	public var server:Socket = null;
	public var socket:Socket = null;
	var isClosed = false;
	
	public function new(remote:SteamID) {
		super(remote);
	}
	override public function closeSocket():Void {
		if (!isClosed) try {
			isClosed = true;
			socket.close();
		} catch (x:Dynamic) {
			printError("[tcp close error]", x);
		}
	}
	
	override public function bindServer(url:String, port:Int):Bool {
		try {
			server = new Socket();
			server.bind(new Host(url), port);
			server.listen(1);
			return true;
		} catch (x:Dynamic) {
			exit("Failed to host a server: " + x);
			return false;
		}
	}
	override public function awaitClientConnection():Bool {
		socket = server.accept();
		socket.setBlocking(false);
		return true;
	}
	override public function connectToServer(url:String, port:Int):Bool {
		try {
			socket = new Socket();
			socket.connect(new Host(url), port);
			socket.setBlocking(false);
			return true;
		} catch (x:Dynamic) {
			println("Failed to connect! " + x);
			return false;
		}
	}
	
	override public function readFromSocket(fn:Bytes->Int->Int->Void):Void {
		var select = Socket.select([socket], [], [], Params.pollTimeout);
		if (select.read.length == 0) {
			
			return;
		}
		
		try {
			var pair = socket.input.readAllNonBlocking();
			if (pair.eof) hasError = true;
			var bytes = pair.bytes;
			fn(bytes, 0, bytes.length);
		} catch (x:Dynamic) {
			printError("[tcp read error]", x);
			hasError = true;
		}
	}
	override public function writeToSocket(bytes:Bytes, pos:Int, len:Int):Bool {
		var result = true;
		try {
			socket.output.writeBytesNonBlockingAsBlocking(bytes, pos, len);
			socket.output.flush();
		} catch (x:Dynamic) {
			printError("[tcp write error]", x);
			hasError = true;
			result = false;
		}
		return result;
	}
	
	override public function writeToSteam(bytes:Bytes, pos:Int, len:Int):Void {
		var chunkSize = 512 * 1024;
		if (len > chunkSize) {
			// k_EP2PSendReliable is up to 1MB, so larger blobs have to be split manually
			var segPos = 0;
			while (segPos < len) {
				var kind = segPos > 0 ? Packet.ChunkPart : Packet.ChunkStart;
				var segEnd = segPos + chunkSize;
				if (segEnd >= len) {
					segEnd = len;
					kind = Packet.ChunkEnd;
				}
				var segSize = segEnd - segPos;
				var segBytes = Bytes.alloc(segSize + 1);
				segBytes.set(0, kind);
				segBytes.blit(1, bytes, pos + segPos, segSize);
				Steam.networking.sendPacket(remote, segBytes, segSize + 1, EP2PSend.RELIABLE);
				segPos = segEnd;
			}
		} else {
			var nb = Bytes.alloc(len + 5);
			nb.set(0, Packet.Data);
			nb.setInt32(1, len);
			nb.blit(5, bytes, pos, len);
			Steam.networking.sendPacket(remote, nb, nb.length, EP2PSend.RELIABLE);
		}
	}
}