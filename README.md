# Steam P2P adapter (working title)

Ever try playing a videogame on Steam with your friend only to realize that you cannot because the game doesn't implement Steam networking/matchmaking
and neither of you can port forward due to being behind a few too many layers of NAT?
This tool solves that specific problem.

## How does it work

The premise is simple enough:

A game with "direct" (IP-port connections) works like this (very simplified):

> Game 1 ⇄ The Internet ⇄ Game 2

A game that implements Steamworks P2P networking works like this:

> Game 1 ⇄ Steam client 1 ⇄ The Internet ⇄ Steam client 2 ⇄ Game 2

This tool acts as an intermediary:

> Game 1 ⇄ Tool 1 ⇄ Steam client 1 ⇄ The internet ⇄ Steam client 2 ⇄ Tool 2 ⇄ Game 2

So that:

- You connect to the tool instead of the other player.
- The tool uses Steamworks SDK to establish a P2P connection to them and sends the data that way.
- The tool running on the other player's end connects to their local server on your behalf and sends the data coming through.

This way, you can avoid port forwarding so long as Steam can establish a P2P connection (which is in most cases since Valve had almost two decades to deal with NAT traversal issues).

## How to use

- Enter the game's Steam App ID (the number seen in store URLs) into `steam_appid.txt` on both ends and run the tool.  
	If the game is free, you may have to use a different App ID
	(e.g. `480` for SDK demo app)
	since free apps do not have the matchmaking API enabled by default.  
	Make sure that Steam client is running!
- The person hosting a server (host) picks Server.  
	Enter the IP to connect to (`127.0.0.1` if hosted on the same machine)
	and port (determined by the game).
- The person joining (guest) picks Client.  
	Enter the IP to host an adapter on (`127.0.0.1` if connecting from the same machine) and port.
	If the game does not prompt to enter a port when connecting, make sure to use the port that the game expects the server to be running on!
- Either have the host invite the guest using Steam Friends window 
	(right-click on friend name, pick "Invite to Lobby")
	or have the guest join themselves via Steam Friends window
	(right-click on friend name, pick "Join lobby").
- Once the tool has established a P2P connection, the guest will see a prompt like "You can now connect to 127.0.0.1:5394...". At this point you can order your game to connect to said IP-port and play the videogame!

## Limitations and caveats

- Only supports two players per session   
	(though you can technically run multiple copies of the tool on host's end)
- Does not support forwarding socket errors - if something goes wrong, you'll get either a generic "connection closed" or a "connection timeout". Inspecting the tool's output may reveal the actual problem.
- No Mac/Linux builds unless you compile them yourself (see below)
- The tool has no knowledge of what application it's communicating with,
	so it's on you not to do anything stupid/insecure.

## Compiling

First-time setup:
- Install [Haxe](https://haxe.org) if you didn't yet
- Install dependencies:
	```bat
	haxelib install hxcpp
	haxelib git SteamWrap https://github.com/YAL-Forks/SteamWrap
	```
- Run `setup.bat` (Windows) or `setup.sh` (Mac, Linux) in SteamWrap's directory.

Then:
```bat
haxe -debug -lib SteamWrap -cp src -cpp bin -main Main
```
When making a build, don't forget to copy the appropriate `steamwrap.ndll` into the ZIP.