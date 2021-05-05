package ;
import SysTools.*;
import cpp.AtomicInt;
import haxe.io.Bytes;
import steamwrap.api.Matchmaking;
import steamwrap.api.Matchmaking.LobbyType;
import steamwrap.api.Networking;
import steamwrap.api.Networking.EP2PSend;
import steamwrap.api.Steam;
import sys.net.Host;
import sys.net.Socket;
import sys.thread.Thread;

/**
 * ...
 * @author YellowAfterlife
 */
class Client {
	public static function main() {
		SteamTools.init();
		var url:String, port:Int;
		if (SteamTools.skipInputs) {
			url = "127.0.0.1";
			port = 5395;
		} else {
			url = Params.host;
			if (url == null) url = gets("What IP to host relay on", "127.0.0.1");
			port = Params.port;
			if (port == -1) port = geti("What port to host relay on", 5394);
		}
		var mtmk:Matchmaking = Steam.matchmaking;
		var net:Networking = Steam.networking;
		
		var lobbyJoined = false;
		mtmk.whenLobbyJoinRequested = function(e) {
			mtmk.joinLobby(e.lobbyID);
		}
		mtmk.whenLobbyJoined = function(ok) {
			lobbyJoined = ok;
		}
		println("Waiting for you to join a lobby...");
		while (!lobbyJoined) {
			Steam.onEnterFrame();
			Sys.sleep(0.1);
		}
		println("Joined a lobby!");
		
		var remote = mtmk.getLobbyOwner();
		println('Waiting for P2P connection from $remote...');
		SteamTools.discardPackets();
		SteamTools.sendSimple(remote, Packet.Hello);
		var gotGreet = false;
		while (mtmk.getLobbyMembers() >= 2 && !gotGreet) {
			while (net.receivePacket()) {
				var pktRemote = net.getPacketSender();
				//trace('Packet from $pktRemote');
				if (pktRemote != remote) continue;
				var bytes = net.getPacketData();
				if (bytes.get(0) == Packet.HelloYes) {
					gotGreet = true;
					break;
				}
			}
			if (gotGreet) break;
			Steam.onEnterFrame();
			Sys.sleep(0.01);
		}
		if (!gotGreet) exit("Player left without a greet");
		
		var server = new Socket();
		println("Creating a server...");
		try {
			server.bind(new Host(url), port);
			server.listen(1);
		} catch (x:Dynamic) {
			exit("Failed to host a server: " + x);
		}
		
		while (mtmk.getLobbyMembers() >= 2) {
			println('You can now connect to $url:$port...');
			var skt = server.accept();
			println("Socket connected!");
			SteamTools.sendSimple(remote, Packet.Connect);
			Adapter.proc(skt, remote);
			println("Socket disconnected!");
			SteamTools.sendSimple(remote, Packet.Disconnect);
		}
		
		switch (mtmk.getLobbyMembers()) {
			case 1: println("Host has left.");
			case 0: println("Lobby has expired.");
		}
	}
}