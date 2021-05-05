package ;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Eof;
import haxe.io.Error;
import haxe.io.Input;
import haxe.io.Output;

/**
 * ...
 * @author YellowAfterlife
 */
class BytesTools {
	/**
	 * Reads all currently available bytes from a socket in non-blocking mode.
	 */
	public static function readAllNonBlocking(input:Input):{bytes:Bytes,eof:Bool} {
		var total:BytesBuffer = new BytesBuffer();
		var eof = false;
		var len = 0;
		try {
			while (true) {
				total.addByte(input.readByte());
				len += 1;
			}
		} catch (x:Error) {
			switch (x) {
				case Blocked: // OK!
				default: throw x;
			}
		} catch (x:Eof) {
			eof = true;
		}
		
		var bytes:Bytes = total.getBytes();
		if (bytes.length > len) {
			bytes = bytes.sub(0, len);
		}
		
		return { bytes: bytes, eof: eof };
	}
	
	/**
	 * Writes bytes to a socket in non-blocking mode synchronously
	 * (waiting until the output becomes available)
	 */
	public static function writeBytesNonBlockingAsBlocking(output:Output, bytes:Bytes, pos:Int, len:Int) {
		var till = pos + len;
		var data = bytes.getData();
		while (pos < till) {
			try {
				while (pos < till) {
					#if cpp
					output.writeByte(data[pos]);
					#else
					output.writeByte(bytes.get(pos));
					#end
					pos += 1;
				}
			} catch (x:Error) {
				switch (x) {
					case Blocked: // sync wait
					default: throw x;
				}
			}
		}
	}
}