package ;
import haxe.CallStack;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Eof;
import haxe.io.Error;
import steamwrap.api.Networking.EP2PSend;
import steamwrap.api.Steam;
import steamwrap.api.SteamID;
import sys.net.Socket;
import sys.thread.Mutex;
import sys.thread.Thread;
import SysTools.*;
using BytesTools;

/**
 * ...
 * @author YellowAfterlife
 */
class Adapter {
	public static var logPackets:Bool = false;
	public static var logData:Bool = false;
	static inline var maxLogBytes = 16;
	public static function proc(socket:Socket, remote:SteamID) {
		socket.setBlocking(false);
		var mtx = new Mutex();
		inline function mtxAcquire():Void {
			//print("Acquiring mutex...");
			mtx.acquire();
			//println("OK!");
		}
		var nextPackets:Array<Bytes> = [];
		var hasError = false;
		var thread = Thread.create(function() {
			var bufsize = (1 << 14);
			var buf = Bytes.alloc(bufsize);
			while (true) {
				var select = Socket.select([socket], [], [], 0.001);
				if (select.read.length == 0) {
					//Sys.sleep(0.01);
					continue;
				}
				var hasMtx = false;
				try {
					var pair = socket.input.readAllNonBlocking();
					var doExit = pair.eof;
					var bytes = pair.bytes;
					
					mtxAcquire();
					hasMtx = true;
					var len = bytes.length;
					if (len != 0) {
						if (logPackets) println("socket -> " + bytes.length + "B -> steam");
						if (logData) {
							print("socket -> " + bytes.length + "B -> steam");
							var n = len > maxLogBytes ? maxLogBytes : len;
							for (i in 0 ... n) {
								print(" " + StringTools.hex(bytes.get(i), 2));
							}
							println("");
						}
						nextPackets.push(bytes);
					}
					if (doExit) {
						hasError = true;
					} else if (hasError) {
						doExit = true;
					}
					mtx.release();
					
					if (doExit) {
						println("[socket thread] gone!");
						return;
					}
				} catch (x:Dynamic) {
					if (!hasMtx) mtxAcquire();
					println("[socket thread] Error: " + x
						+ "\n" + CallStack.toString(CallStack.exceptionStack(true)));
					hasError = true;
					mtx.release();
					return;
				}
			}
		});
		var chunkBuilder:BytesBuffer = null;
		while (Steam.matchmaking.getLobbyID() != SteamID.defValue) {
			Sys.sleep(0.01);
			//Steam.onEnterFrame(); // not necessary - no events at this point
			SteamTools.keepAlive(remote);
			//
			mtxAcquire();
			var doExit = hasError;
			var packets = nextPackets;
			nextPackets = [];
			mtx.release();
			//
			for (bytes in packets) {
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
			//
			if (doExit) {
				println("[main thread] gone!");
				return;
			}
			//
			while (Steam.networking.receivePacket()) {
				if (Steam.networking.getPacketSender() != remote) continue;
				
				inline function handleData(bytes:Bytes, pos:Int, len:Int, ?chunked:Bool) {
					if (logData) {
						print("steam -> " + len + "B -> socket");
						if (chunked) print(" [chunked]");
						var n = len > maxLogBytes ? maxLogBytes : len;
						for (i in 0 ... n) {
							print(" " + StringTools.hex(bytes.get(pos + i), 2));
						}
						println("");
					}
					
					var result = false;
					try {
						socket.output.writeBytesNonBlockingAsBlocking(bytes, pos, len);
						socket.output.flush();
					} catch (x:Dynamic) {
						mtxAcquire();
						println("[main thread] Error while writing: " + x
							+ "\n" + CallStack.toString(CallStack.exceptionStack(true)));
						hasError = true;
						mtx.release();
						result = true;
					}
					return result;
				}
				
				var bytes = Steam.networking.getPacketData();
				var len = bytes.length;
				if (len == 0) continue;
				var kind = bytes.get(0);
				if (logPackets) print('steam -> ${len}B[$kind] -> ');
				
				switch (kind) {
					case Packet.Data:
						if (logPackets) println("socket");
						if (handleData(bytes, 5, len - 5)) return;
					case Packet.ChunkStart:
						chunkBuilder = new BytesBuffer();
						chunkBuilder.addBytes(bytes, 1, len - 1);
						//println("chunk start: " + (len - 1));
					case Packet.ChunkPart:
						//println("chunk part: " + (len - 1));
						chunkBuilder.addBytes(bytes, 1, len - 1);
					case Packet.ChunkEnd:
						chunkBuilder.addBytes(bytes, 1, len - 1);
						var cl = chunkBuilder.length;
						var cb = chunkBuilder.getBytes();
						//println("chunk end: " + (len - 1) + ', $cl total');
						if (handleData(cb, 0, cl, true)) return;
						chunkBuilder = null;
					case Packet.Disconnect:
						if (logPackets) println("bye!");
						mtxAcquire();
						hasError = true;
						try {
							socket.close();
						} catch (x:Dynamic) {
							println("[main thread] Error while closing socket: " + x
								+ "\n" + CallStack.toString(CallStack.exceptionStack(true)));
						}
						mtx.release();
						return;
					case Packet.KeepAlive:
						if (logPackets) println("poke");
					default:
						if (logPackets) println("???");
				}
			}
		}
	}
}