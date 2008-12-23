
package com.darronschall.utils {
	
	/**
	 * Utility class to provide helper methods for int
	 */
	 public final class IntUtil {
	
		/** 
		 * Rotate first i bits in v n steps to the left. 
		 */
		public static function rol( v:int, i:int, n:int ):int {
			// Figure out the bits that will be rotated off the end
			var off:int = ( v >> (i - n) ) & ( (1 << n) - 1 );
			// Move the bits to the left
			v = ( v << n ) & ( (1 << i) - 1 );
			// Bring back in the bits that we lost
			return v | off;
		}
		
	}
}		