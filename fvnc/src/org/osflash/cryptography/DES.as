/*
 * FVNC: A VNC Client for Flash Player 9 and above
 * Copyright (C) 2005-2007 Darron Schall <darron@darronschall.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
 * 02111-1307 USA
 */	
package org.osflash.cryptography 
{
import flash.utils.ByteArray;
import com.darronschall.utils.*;

/**
 * DES encryption algorithm based on FIPS PUB 46 
 * http://www.itl.nist.gov/fipspubs/fip46-2.htm
 *
 * This class has a special VNC methods that tailor to
 * the fact that the least signification bit comes first
 * when getting a bit from the key schedule in VNC
 * authentication.  To use the "regular" DES encryption
 * just ignore the second parameter in the constructor.
 */
 public class DES
 {

	private static var _IP:Array; // int[]
	private static var _IPR:Array; // int[]
	private static var _ET:Array; // int[]
	private static var _P:Array; // int[]
	private static var _LS:Array; // int[]
	private static var _PC1:Array; // int[]
	private static var _PC2:Array; // int[]
	private static var _S:Array; // int[][]
	
	private var key:ByteArray;
	private var ks:Array; // byte[][]
	
	/** 
	 * Loads values into the arrays.  This must be done before 
	 * encrypting and is a separate process to save memory (the
	 * arrays won't take up memory space unless they need to 
	 * actually be used).
	 */
	public static function load():void
	{
		createIP();
		createET();
		createP();
		createLS();
		createPC();
		createS();
	}
	
	/** 
	 * Frees up memory by deleting all arrays so the garbage
	 * collector can reclaim the resources
	 */
	public static function unload():void
	{
		_IP = _IPR = _ET = _P = _LS = _PC1 = _PC2 = _S = null;
	}
	
	/**
	 * Constructor, create a new DES encrypt/decrypter using a 
	 * specified key (password).  Must call the static load 
	 * method before using.
	 */
	 
	public function DES( key:String, vncBits:Boolean = false )
	{
		this.key = StringUtil.toByteArray( key );
		
		// pad / truncate as necessary to make sure length is 8
		this.key.length = 8;
		
		calculateKS( vncBits );
	}
	
	/** 
	 * Calculate key schedules
	 *
	 * @param vncBits A flag indicating the order for getting the bits
	 */
	private function calculateKS( vncBits:Boolean ):void
	{
		var c:int = 0;
		var d:int = 0;
		var i:int;
		var j:int;
		
		ks = new Array(16);
		for ( i  = 0; i < 28; i++ )
		{
			if ( vncBits )
			{
				c = NumberUtil.sb( c, i, 28, vncgb( key, _PC1[ i ] ) );
				d = NumberUtil.sb( d, i, 28, vncgb( key, _PC1[ i + 28 ] ) );
			}
			else
			{
				c = NumberUtil.sb( c, i, 28, ByteArrayUtil.gb( key, _PC1[ i ] ) );
				d = NumberUtil.sb( d, i, 28, ByteArrayUtil.gb( key, _PC1[ i + 28 ] ) );
			}
		}
		for ( i = 0; i < 16; i++ )
		{
			var cd:ByteArray;
			var cdp:ByteArray;
			c = IntUtil.rol( c, 28, _LS[ i ] );
			d = IntUtil.rol( d, 28, _LS[ i ] );
			
			cd = new ByteArray();
			cd.length = 7;

			cd.writeInt( c << 4 );
			cd.position = 3;
			cd.writeInt( c << 28 | d );
			
			cdp = new ByteArray();
			cdp.length = 7;
			for ( j = 0; j < 48; j++ )
			{
				ByteArrayUtil.sb( cdp, j, ByteArrayUtil.gb( cd, _PC2[ j ] ) );
			}
			ks[ i ] = cdp;
		}
	}
	
	/** 
	 * Encrypts the ByteArray
	 * 
	 * @param b a ByteArray to be encrypted, must be of length 8
	 */
	public function encrypt( b:ByteArray ):ByteArray
	{ 
		var L:ByteArray = new ByteArray();
		var R:ByteArray = new ByteArray();
		var EL:ByteArray;
		var ER:ByteArray;
		var i:int;
		
		L.length = 4;
		R.length = 4;
		
		// Perform initial permutation
		b = permutate( b, true ); 
		
		b.position = 0;
		b.readBytes( L, 0, 4 );
		b.position = 4;
		b.readBytes( R, 0, 4 );
		
		for ( i = 0; i < 32; i++ )
		{
			ByteArrayUtil.sb( L, i, ByteArrayUtil.gb( b, i ) );
			ByteArrayUtil.sb( R, i, ByteArrayUtil.gb( b, i + 32 ) );
		}
		
		for ( i = 0; i < 16; i++ )
		{
			EL = R; // L' = R
			ER = ByteArrayUtil.xor( L, f( R, ks[i] ) ); // R' = L (+) f( R, Kn )
			
			L = EL;
			R = ER;
		}
								
		// Append, with R first.
		var r:ByteArray = ByteArrayUtil.concat( R, L );
		
		// Perform final permutation
		return permutate( r, false );
	}
	
	/** 
	 * Perform permutation
	 */
	private static function permutate( b:ByteArray, f:Boolean ):ByteArray
	{
		var a:ByteArray = new ByteArray();
		var i:int;
		
		a.length = 8;
		
		if ( f )
		{
			for ( i = 0; i < 64; i++ )
			{
				ByteArrayUtil.sb( a, i, ByteArrayUtil.gb( b, _IP[ i ] ) );
			}
		} else
		{
			for ( i = 0; i < 64; i++ )
			{
				ByteArrayUtil.sb( a, i, ByteArrayUtil.gb( b, _IPR[ i ] ) );
			}
		}
		
		return a;
	}
	
	/** 
	 * Perform P
	 */
	private static function P( b:ByteArray ):ByteArray
	{
		var r:ByteArray = new ByteArray();
		r.length = 4;
		
		for ( var i:int = 0; i < 32; i++ )
		{
			ByteArrayUtil.sb( r, i, ByteArrayUtil.gb( b, _P[ i ] ) );
		}
		
		return r;
	}
	
	/** 
	 * Perform E
	 */
	private static function E( b:ByteArray ):ByteArray
	{
		var n:ByteArray = new ByteArray();
		n.length = 6;
		
		for ( var i:int = 0; i < 48; i++ )
		{
			ByteArrayUtil.sb( n, i, ByteArrayUtil.gb( b, _ET[ i ] ) );
		}
		return n;
	}
	
	/** 
	 * Perform S
	 */
	private static function S( n:ByteArray ):ByteArray
	{
		var r:ByteArray = new ByteArray();
		var i:int;
		var s:int;
		var j:int;
		
		r.length = 4;
		
		for( i = 0; i < 8; i++ )
		{
			s = 0;
			for ( j = 0; j < 6; j++ )
			{
				s = ( s << 1 ) | int( ByteArrayUtil.gb( n, i * 6 + j ) );
			}
			r[ Math.floor(i/2) ] |= Sn( i, s) << ( ( i % 2 ) == 0 ? 4 : 0 );
		}
		return r;
	}
	
	/** 
	 * Performs lookup in S
	 */
	private static function Sn( i:int, n:int ):int
	{
		var a:int = ( n >> 4 ) & 2 | ( n & 1 );
		var b:int = ( n >> 1 ) & 0x0F;
		return _S[ i ][ a * 16 + b ];
	}
	
	/** 
	 * Performs f
	 */
	private static function f( R:ByteArray, K:ByteArray ):ByteArray
	{
		return P( S( ByteArrayUtil.xor( E( R ), K ) ) ); 
	}
	
	/** 
	 * Gets bit number n from a ByteArray, but in the wrong order
	 * for the "VNC way"
	 */
	private static function vncgb( b:ByteArray, n:int ):Boolean
	{
		return Boolean( ( b[n >> 3] >> ( n & 0x07 ) ) & 1 );
	}
	
	/** 
	 * Create the initial permutation tables
	 */
	private static function createIP():void
	{
		var i:int;
		var j:int;
		
		_IP = new Array(64);
		_IPR = new Array(64);
		
		// generate initial permutation table
		for ( i = 0; i < 64; i++ )
		{
			_IP[ i ] = (((( i >> 3 ) << 1 ) + 1 ) % 9 )
					  + (( 7 - ( i & 0x07 ) ) << 3 );
		}
		// generate the inverse initial permutation table
		for ( i = 0; i < 64; i++ )
		{
			for ( j = 0; j < 64; j++ )
			{
				if( _IP[ j ] == i )
				{
					_IPR[ i ] = j;
				}
			}
		}
	}
	
	/** 
	 * Create E Bit-Selection table
	 */
	private static function createET():void
	{
		var n:int = 31;
		_ET = new Array(48);
		
		for( var i:int = 0; i < 48; i++ )
		{
			_ET[ i ] = n;
			
			if( i % 6 == 5 )
			{
				n--;
			}
			else
			{
				n++;
			}
			n &= 0x1F;
		}
	}
	
	/**
	 * Create S
	 */
	private static function createS():void
	{
		_S = new Array( 8 );
		_S[ 0 ] = [14,4,13,1,2,15,11,8,3,10,6,12,5,9,0,7,0,15,7,4,14,2,13,1,10,6,12,11,9,5,3,8,4,1,14,8,13,6,2,11,15,12,9,7,3,10,5,0,15,12,8,2,4,9,1,7,5,11,3,14,10,0,6,13];
		_S[ 1 ] = [15,1,8,14,6,11,3,4,9,7,2,13,12,0,5,10,3,13,4,7,15,2,8,14,12,0,1,10,6,9,11,5,0,14,7,11,10,4,13,1,5,8,12,6,9,3,2,15,13,8,10,1,3,15,4,2,11,6,7,12,0,5,14,9];
		_S[ 2 ] = [10,0,9,14,6,3,15,5,1,13,12,7,11,4,2,8,13,7,0,9,3,4,6,10,2,8,5,14,12,11,15,1,13,6,4,9,8,15,3,0,11,1,2,12,5,10,14,7,1,10,13,0,6,9,8,7,4,15,14,3,11,5,2,12];
		_S[ 3 ] = [7,13,14,3,0,6,9,10,1,2,8,5,11,12,4,15,13,8,11,5,6,15,0,3,4,7,2,12,1,10,14,9,10,6,9,0,12,11,7,13,15,1,3,14,5,2,8,4,3,15,0,6,10,1,13,8,9,4,5,11,12,7,2,14];
		_S[ 4 ] = [2,12,4,1,7,10,11,6,8,5,3,15,13,0,14,9,14,11,2,12,4,7,13,1,5,0,15,10,3,9,8,6,4,2,1,11,10,13,7,8,15,9,12,5,6,3,0,14,11,8,12,7,1,14,2,13,6,15,0,9,10,4,5,3];
		_S[ 5 ] = [12,1,10,15,9,2,6,8,0,13,3,4,14,7,5,11,10,15,4,2,7,12,9,5,6,1,13,14,0,11,3,8,9,14,15,5,2,8,12,3,7,0,4,10,1,13,11,6,4,3,2,12,9,5,15,10,11,14,1,7,6,0,8,13];
		_S[ 6 ] = [4,11,2,14,15,0,8,13,3,12,9,7,5,10,6,1,13,0,11,7,4,9,1,10,14,3,5,12,2,15,8,6,1,4,11,13,12,3,7,14,10,15,6,8,0,5,9,2,6,11,13,8,1,4,10,7,9,5,0,15,14,2,3,12];
		_S[ 7 ] = [13,2,8,4,6,15,11,1,10,9,3,14,5,0,12,7,1,15,13,8,10,3,7,4,12,5,6,11,0,14,9,2,7,11,4,1,9,12,14,2,0,6,10,13,15,3,5,8,2,1,14,7,4,10,8,13,15,12,9,0,3,5,6,11];
	}
	
	/**
	 * Create P
	 */
	private static function createP():void
	{
		_P = [15,6,19,20,28,11,27,16,0,14,22,25,4,17,30,9,1,7,23,13,31,26,2,8,18,12,29,5,21,10,3,24];
	}
	
	/** 
	 * Create permuted choices
	 */
	private static function createPC():void
	{
		_PC1 = [56,48,40,32,24,16,8,0,57,49,41,33,25,17,9,1,58,50,42,34,26,18,10,2,59,51,43,35,62,54,46,38,30,22,14,6,61,53,45,37,29,21,13,5,60,52,44,36,28,20,12,4,27,19,11,3];
		_PC2 = [13,16,10,23,0,4,2,27,14,5,20,9,22,18,11,3,25,7,15,6,26,19,12,1,40,51,30,36,46,54,29,39,50,44,32,47,43,48,38,55,33,52,45,41,49,35,28,31];
	}
	
	/** 
	 * Create left shift schedule 
	 */
	private static function createLS():void
	{
		_LS = [1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1];
	}
	
} // end class
} // end package