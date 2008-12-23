	
package com.darronschall.utils {
	
	import flash.utils.ByteArray;

	/**
	 * Utility class to provide helper methods for String
	 */
	public class StringUtil {
	
		/** 
		 * Converts a string to a byte array
		 */
		public static function toByteArray( str:String, maxlen:int=0x7FFFFFFF ):ByteArray {
			var len:int = str.length;
			var bytes:ByteArray = new ByteArray();
			
			// Loop over all of the characters in the string and write
			// the character code values as bytes into the byte array
			for ( var i:int = 0; i < len && i < maxlen; i++ ) {
				bytes.writeByte( str.charCodeAt(i) );
			}
			
			return bytes;		
		}
	}
}