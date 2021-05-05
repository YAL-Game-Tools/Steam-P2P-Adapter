package ;
import SysTools.*;
import haxe.io.Bytes;
import steamwrap.api.Matchmaking;
import steamwrap.api.Matchmaking.LobbyType;
import steamwrap.api.Networking;
import steamwrap.api.Steam;
import steamwrap.api.SteamID;
import sys.net.Host;
import sys.net.Socket;

/**
 * ...
 * @author YellowAfterlife
 */
class Server {
	public static function main() {
		SteamTools.init();
		var url:String, port:Int;
		if (SteamTools.skipInputs) {
			url = "127.0.0.1";
			port = 5394;
		} else {
			url = Params.host;
			if (url == null) url = gets("What IP to connect to", "127.0.0.1");
			port = Params.port;
			if (port == -1) port = geti("What port to connect to", 5394);
		}
		var mtmk:Matchmaking = Steam.matchmaking;
		var net:Networking = Steam.networking;
		
		var lobbyCreated:Null<Bool> = null;
		mtmk.whenLobbyCreated = function(ok) {
			lobbyCreated = ok;
		}
		if (!mtmk.createLobby(LobbyType.FRIENDS_ONLY, 2)) {
			exit("Couldn't start creating a lobby!"); return;
		}
		println("Creating a lobby...");
		SteamTools.waitFor(() -> lobbyCreated != null);
		if (!lobbyCreated) {
			exit("failed to create a lobby!");
		}
		
		println("Lobby ID is " + mtmk.getLobbyID());
		println("Waiting for a player to join...");
		SteamTools.waitFor(() -> mtmk.getLobbyMembers() >= 2);
		println("Played joined!");
		
		var remote = mtmk.getLobbyMember(1);
		println('Waiting for P2P connection from $remote...');
		SteamTools.discardPackets();
		var gotGreet = false;
		while (mtmk.getLobbyMembers() >= 2 && !gotGreet) {
			while (net.receivePacket()) {
				var pktRemote = net.getPacketSender();
				if (pktRemote != remote) continue;
				var bytes = net.getPacketData();
				if (bytes.get(0) == Packet.Hello) {
					gotGreet = true;
					SteamTools.sendSimple(remote, Packet.HelloYes);
					break;
				}
			}
			if (gotGreet) break;
			Steam.onEnterFrame();
			Sys.sleep(0.01);
		}
		if (!gotGreet) exit("Player left without a greet");
		println("Waiting for player to connect to their relay...");
		
		while (mtmk.getLobbyMembers() >= 2) {
			var gotConnect = false;
			SteamTools.keepAlive(remote);
			while (net.receivePacket()) {
				var pktRemote = net.getPacketSender();
				if (pktRemote != remote) continue;
				if (net.getPacketData().get(0) == Packet.Connect) {
					gotConnect = true;
					break;
				}
			}
			if (gotConnect) {
				println("Socket connected!");
				var skt = new Socket();
				try {
					skt.connect(new Host(url), port);
				} catch (x:Dynamic) {
					println("Failed to connect!");
					continue;
				}
				Adapter.proc(skt, remote);
				println("Socket disconnected!");
				println("Waiting for player to [re-]connect to their relay...");
			}
		}
		
		switch (mtmk.getLobbyMembers()) {
			case 1: println("Client has left.");
			case 0: println("Lobby has expired.");
		}
	}
}