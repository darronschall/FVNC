
package com.darronschall.utils {
	
	/**
	 * Utility class to provide helper methods for Number
	 */
	 public final class NumberUtil {
	
		/** 
		 * Gets bit number n from a number of i bits 
		 */
		public static function gb( a:Number, n:int, i:int ):Boolean {
			// Extract the bit value and convert it to Boolean
			return Boolean( ( a >> ( i - n - 1 ) ) & 1 );
		}
		
		/** 
		 * Adjusts bit number n in an int of i bits 
		 */
		public static function sb( a:Number, n:int, i:int, on:Boolean ):int {
			// Should the bit be set or not?
			if ( on ) {
				// Shift a 1 to the correct bit location and bitwise or to set
				return a | ( 1 << ( i - n - 1 ) );
			} else {
				// Create all 1s and a single 0 in the correct bit location and
				// bitwise and to remove that bit from a
				return a & ( ~0 - ( 1 << ( i - n - 1 ) ) );
			}
		}
	}
}		