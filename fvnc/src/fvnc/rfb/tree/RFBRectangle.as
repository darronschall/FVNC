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
package fvnc.rfb.tree
{

import flash.display.BitmapData;
import fvnc.rfb.RFBProtocol;

/**
 * A rectangle from the framebuffer
 * fields:
 * Bytes	Type	Description
 * 2		U16	x-position
 * 2		U16	y-position
 * 2		U16	width
 * 2		U16	height
 * 4		S32	encoding-type
 *
 * Encoding types:
 * 0		Raw
 * 1		CopyRect
 * 2		RRE
 * 4		CoRRE
 * 5		Hextile
 * 6		zlib
 * 7		tight
 * 8		zlibhex
 * 16		ZRLE
 * -272 to -257	Anthony Liguori
 * -256 to -240
 * -238 to -224
 * -222 to -1	tight options
 */
public class RFBRectangle extends RFBNode
{
	public var x:int = -1;
	public var y:int = -1;
	public var width:int = -1;
	public var height:int = -1;
	protected var encodingType:int = -1;
	protected var encodingData:RFBEncodingData;
	
	/**
	 * Constructor
	 */
	public function RFBRectangle( parent:RFBNode )
	{
		super( parent );
	}
	
	/**
	 * Create the node.  If the socket doesn't contain enough information, defer
	 * computation until later and raise an exception.
	 * 
	 * @return The next node to be processed or null if this message is complete
	 */
	override public function buildNode( rfb:RFBProtocol ):RFBNode
	{
		// check all of the parameters and complete the ones we haven't gotten to yet
		if ( x == -1 )
		{
			x = rfb.readU16();
		}
		if ( y == -1 )
		{
			y = rfb.readU16();
		}
		if ( width == -1 )
		{
			width = rfb.readU16();
		}
		if ( height == -1 )
		{
			height = rfb.readU16();
		}
		if ( encodingType == -1 )
		{
			encodingType = rfb.readS32();
		}
		
		// Process our data if it hasn't been done yet
		if ( encodingData == null )
		{
			// Create the appropiate pixel data decoder
			switch ( encodingType )
			{
				case 0: // Encoding.RAW
					encodingData = new RFBEncodingRaw( this );
					break;
				
				case 1: // Encoding.COPY_RECT
					encodingData = new RFBEncodingCopyRect( this );
					break;
				
				case 2: // Encoding.RRE
					encodingData = new RFBEncodingRRE( this );
					break;
					
				case 5: // Encoding.HEXTILE
					encodingData = new RFBEncodingHexTile( this );
					break;
					
				case 16: // Encoding.ZRLE
					//encodingData = new RFBEncodingZRLE( this );
					break;
				
				case -239: // Encoding.CURSOR
					encodingData = new RFBEncodingCursor( this );
					break;
					
				default:
					// Ack, we don't support this encoding type
					throw new Error( "Unsupported encoding: " + encodingType );
			}
			
			return encodingData;
		}
		
		// if we already processed our data, hand control back to the parent
		return parent;
	}
	
	/**
	 * 
	 */
	override public function execute( screenImageData:BitmapData ):void
	{
		encodingData.execute( screenImageData );
	}

} // end class
} // end package
