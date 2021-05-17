package;
import haxe.io.Bytes;
import haxe.io.Input;
import haxe.io.Output;

/**
 * ...
 * @author YellowAfterlife
 */
enum abstract Packet(Int) from Int to Int {
	var Hello = 100;
	var HelloYes = 101;
	var KeepAlive = 102;
	var Connect = 110;
	var Disconnect = 111;
	var Data = 120;
	var ChunkStart = 121;
	var ChunkPart = 122;
	var ChunkEnd = 123;
	var UdpData = 124;
}