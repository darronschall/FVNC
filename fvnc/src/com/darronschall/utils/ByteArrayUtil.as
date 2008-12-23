
package com.darronschall.utils {
	
	import flash.utils.ByteArray;
	import com.darronschall.utils.NumberUtil;
	
	/**
	 * Utility class to provide helper methods for ByteArray
	 */
	final public class ByteArrayUtil {
		
		/**
		 * Output the contents of a ByteArray as a string
		 */
		public static function dump( bytes:ByteArray, asHex:Boolean = true ):String {
			var output:String = "";
			var len:uint = bytes.length;
			
			bytes.position = 0;
			
			for (var i:int = 0; i < len; i++) {
				// Append the byte with a space for some separation
				if ( asHex ) {
					output += bytes.readByte().toString(16).toUpperCase() + " ";
				} else {
					output += bytes.readByte() + " ";
				}
			}
			
			return output;
		}	
		
		/** 
		 * "Bitwise addition modulo 2", xor two byte arrays that are 
		 * assumed to be the same length.
		 */
		public static function xor(a:ByteArray, b:ByteArray):ByteArray {
			var c:ByteArray = new ByteArray();
			var len:int = a.length;
			var i:int;
			
			for (i = 0; i < a.length; i++) {
				c.writeByte( a[i] ^ b[i] );
			}
			return c;
		}
		
		/** 
		 * Adjusts bit number n in a ByteArray. 
		 */
		public static function sb( b:ByteArray, n:int, on:Boolean ):void {
			// Determine if the bit should be set (on) or not
			if ( on ) {
				// n >> 3 gives us which byte position the bit will be in
				// Place a 1 in the correct bit location and bitwise or to
				// set the value.
				b[n >> 3] = b[ n >> 3] | ( 1 << ( 7 - ( n & 0x07 ) ) );
			} else {
				// n >> 3 gives us the byte position the bit will be in
				// Places all 1s and a single 0 in the correct bit location
				// and bitwise and to turn off the particular bit
				b[n >> 3] = b[ n >> 3] & ( ~0 - ( 1 << ( 7 - ( n & 0x07 ) ) ) );
			}
		}
		
		/** 
		 * Gets bit number n from a ByteArray
		 */
		public static function gb( b:ByteArray, n:int ):Boolean {
			// Extract the bit value and convert it to Boolean
			return Boolean( ( b[n >> 3] >> ( 7 - ( n & 0x07 ) ) ) & 1 );
		}
		
		/**
		 * Parses a hex string into a ByteArray
		 */
		public static function hexToByteArray( hex:String ):ByteArray {
			var bytes:ByteArray = new ByteArray();
			// Extract the int value from the hex string via parseInt with radix 16
			var intValue:int = parseInt( hex, 16 );
			// Write the int value into the byte array
			bytes.writeInt( intValue );
			return bytes;
		}
		
		/** Convert b bits of a to a ByteArray of length n */
		public static function numberToByteArray( a:Number, n:int, b:int):ByteArray {
			var t:ByteArray = new ByteArray();
			var i:int;
			
			t.length = n;
			for ( i = 0; i < b; i++ ) {
				sb( t, i, NumberUtil.gb( a, i, b ) );
			}
			return t;
		}
		
		/** Create a new ByteArray c that is the same as a followed by b */
		public static function concat( a:ByteArray, b:ByteArray ):ByteArray {
			var c:ByteArray = new ByteArray();
			c.length = a.length + b.length;
			
			a.position = 0;
			b.position = 0;
			
			a.readBytes(c, 0, a.length);
			b.readBytes(c, a.length, b.length);
			
			return c;
		}
	}
}