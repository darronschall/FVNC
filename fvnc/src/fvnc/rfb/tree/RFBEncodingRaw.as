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
import flash.geom.Point;

import fvnc.rfb.RFBProtocol;	
	
/**
 * FramebufferUpdate encoding 0 - Raw
 */
public class RFBEncodingRaw extends RFBEncodingData
{
	private var pixels:BitmapData;
	
	/** The current x location being processed */
	private var x:int = 0;
	
	/** The current y location being processed */
	private var y:int = 0;
		
	/**
	 * 
	 */
	public function RFBEncodingRaw( parent:RFBRectangle )
	{
		super( parent );
		
		pixels = new BitmapData( parent.width, parent.height, false, 0x000000 );
	}
	
	/**
	 * Create the node.  If the socket doesn't contain enough information, defer
	 * computation until later and raise an exception.
	 * 
	 * @return The next node to be processed or null if this message is complete
	 */
	override public function buildNode( rfb:RFBProtocol ):RFBNode
	{
		var container:RFBRectangle = RFBRectangle( parent );
		
		// Build our pixel array
		for ( ; y < container.height; y++ )
		{
			for ( ; x < container.width; x++ )
			{
				pixels.setPixel( x, y, rfb.readPixel() );
			}
			x = 0;
		}
		
		return parent;
	}
	
	/**
	 * 
	 */
	override public function execute( screenImageData:BitmapData ):void
	{
		var container:RFBRectangle = RFBRectangle( parent );
		var dstPoint:Point = new Point( container.x, container.y );

		screenImageData.copyPixels( pixels, pixels.rect, dstPoint );
		
		pixels.dispose();
	}

} // end class
} // end package