package adapter;

import haxe.io.Bytes;
import steamwrap.api.Networking.EP2PSend;
import steamwrap.api.Steam;
import steamwrap.api.SteamID;
import sys.net.Address;
import sys.net.Host;
import sys.net.Socket;
import sys.net.UdpSocket;
import SysTools.*;

/**
 * ...
 * @author YellowAfterlife
 */
class UdpAdapter extends Adapter {
	public var socket:UdpSocket;
	var readBuffer:Bytes = Bytes.alloc(1024 * 64);
	var readAddress:Address = new Address();
	var boundAddress:Address = null;
	var allowRebind = true;
	var canRebind = false;
	var isClosed = false;
	var lastHeardFrom = 0.;
	
	public function new(remote:SteamID) {
		super(remote);
		socket = new UdpSocket();
		socket.setBlocking(false);
	}
	override public function closeSocket():Void {
		if (!isClosed) try {
			isClosed = true;
			socket.close();
		} catch (x:Dynamic) {
			printError("[udp close error]", x);
		}
	}
	
	override public function bindServer(url:String, port:Int):Bool {
		try {
			var host = new Host(url);
			socket.bind(host, port);
			return true;
		} catch (x:Dynamic) {
			exit("Failed to host a server: " + x);
			return false;
		}
	}
	override public function awaitClientConnection():Bool {
		while (canUpdate()) {
			var select = Socket.select([socket], [], [], Params.pollTimeout);
			if (select.read.length > 0) return true;
		}
		return false;
	}
	
	override public function connectToServer(url:String, port:Int):Bool {
		var host = new Host(url);
		boundAddress = new Address();
		boundAddress.host = host.ip;
		boundAddress.port = port;
		allowRebind = false;
		return true;
	}
	
	private static function printAddr(addr:Address) {
		return addr.getHost().toString() + ":" + addr.port;
	}
	override public function readFromSocket(fn:Bytes->Int->Int->Void):Void {
		var now = Sys.time();
		if (allowRebind && boundAddress != null) {
			if (!canRebind && now > lastHeardFrom + Params.udpTimeout) {
				canRebind = true;
				println("Connection timed out, allowing re-bind");
			}
		}
		
		var select = Socket.select([socket], [], [], 0.001);
		if (select.read.length == 0) {
			
			return;
		}
		
		var step = 0;
		var buffer = readBuffer;
		var addr = readAddress;
		while (++step < 1000000) try {
			var len = socket.readFrom(buffer, 0, buffer.length, addr);
			if (boundAddress == null || canRebind) {
				println('Binding to ${printAddr(addr)}');
				boundAddress = addr.clone();
				canRebind = false;
			} else if (boundAddress.compare(addr) != 0) {
				continue;
			}
			lastHeardFrom = now;
			fn(buffer, 0, len);
		} catch (_:Dynamic) {
			break;
		}
	}
	override public function writeToSocket(bytes:Bytes, pos:Int, len:Int):Bool {
		if (boundAddress == null) {
			println("[udp send error] No remote address bound!");
			return false;
		}
		try {
			socket.sendTo(bytes, pos, len, boundAddress);
		} catch (x:Dynamic) {
			printError("[udp send error]", x);
		}
		return true;
	}
	override public function writeToSteam(bytes:Bytes, pos:Int, len:Int):Void {
		var nb = Bytes.alloc(len + 5);
		nb.set(0, Packet.UdpData);
		nb.setInt32(1, len);
		nb.blit(5, bytes, pos, len);
		Steam.networking.sendPacket(remote, nb, nb.length, EP2PSend.UNRELIABLE);
	}
}