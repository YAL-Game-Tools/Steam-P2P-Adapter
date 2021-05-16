package adapter;
import haxe.io.Bytes;
import steamwrap.api.Networking.EP2PSend;
import steamwrap.api.Steam;
import steamwrap.api.SteamID;
import sys.net.Socket;
import SysTools.*;
using BytesTools;

/**
 * ...
 * @author YellowAfterlife
 */
class TcpAdapter extends Adapter {
	public var socket:Socket;
	
	public function new(tcpSocket:Socket, remote:SteamID) {
		super(remote);
		socket = tcpSocket;
		socket.setBlocking(false);
	}
	override public function readFromSocket(fn:Bytes->Void):Void {
		var select = Socket.select([socket], [], [], 0.001);
		if (select.read.length == 0) {
			
			return;
		}
		
		try {
			var pair = socket.input.readAllNonBlocking();
			if (pair.eof) hasError = true;
			fn(pair.bytes);
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
	override public function closeSocket():Void {
		try {
			socket.close();
		} catch (x:Dynamic) {
			printError("[tcp close error]", x);
		}
	}
	
	override public function writeToSteam(bytes:Bytes):Void {
		var len = bytes.length;
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
				segBytes.blit(1, bytes, segPos, segSize);
				Steam.networking.sendPacket(remote, segBytes, segSize + 1, EP2PSend.RELIABLE);
				segPos = segEnd;
			}
		} else {
			var nb = Bytes.alloc(len + 5);
			nb.set(0, Packet.Data);
			nb.setInt32(1, len);
			nb.blit(5, bytes, 0, len);
			Steam.networking.sendPacket(remote, nb, nb.length, EP2PSend.RELIABLE);
		}
	}
}