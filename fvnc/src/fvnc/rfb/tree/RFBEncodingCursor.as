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
import flash.errors.EOFError;
import flash.utils.ByteArray;

import fvnc.rfb.RFBProtocol;	
	
/**
 * FramebufferUpdate encoding -239 - Cursor
 */
public class RFBEncodingCursor extends RFBEncodingData
{
	/**
	 * Constructor
	 */
	public function RFBEncodingCursor( parent:RFBRectangle )
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
		var rect:RFBRectangle = RFBRectangle( parent );
		var w:int = rect.width;
		var h:int = rect.height;
		
		var requiredBytes:int = ( w * h * rfb.bytesPerPixel ) 
							  + ( Math.floor( ( w + 7 ) / 8 ) * h );
		
		// Make sure we have enough data before continueing
		if ( requiredBytes > rfb.bytesAvailable )
		{
			throw new EOFError();
		}
				
		// Skip the data in the cursor update since we have the local 
		// mouse...
		var tmp:ByteArray = new ByteArray();
		
		rfb.readBytes( tmp, 0, w * h * rfb.bytesPerPixel );
		rfb.readBytes( tmp, 0, Math.floor( ( w + 7 ) / 8 ) * h );
		
		return parent;
	}
	
	/**
	 * 
	 */
	override public function execute( screenImageData:BitmapData ):void
	{
		// Do nothing
	}

} // end class
} // end package