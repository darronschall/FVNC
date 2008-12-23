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
import flash.geom.Rectangle;

import fvnc.rfb.RFBProtocol;
import flash.geom.Point;

/**
 * FramebufferUpdate encoding 2 - Rise-and-Run-length Encoding
 * fields:
 * Bytes		Type	Description
 * 4			U32	number-of-subrectangles
 * bytesPerPixel	PIXEL	background-pixel-value
 */
public class RFBEncodingRRE extends RFBEncodingData
{
	private var number_of_subrectangles:uint = 0;
	private var read_number_of_subrectangles:Boolean = false;
	
	private var background_pixel_value:uint;
	private var read_background_pixel_value:Boolean = false;
	
	private var subrectanglesProcessed:int = 0;
	
	private var read_subrect_pixel_value:Boolean = false;
	private var subrect_pixel_value:int = -1;
	private var xPosition:int = -1;
	private var yPosition:int = -1;
	private var width:int = -1;
	private var height:int = -1;
	
	private var pixels:BitmapData;
	
	/**
	 * Constructor
	 */
	public function RFBEncodingRRE( parent:RFBRectangle )
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
		if ( !read_number_of_subrectangles )
		{
			number_of_subrectangles = rfb.readU32();
			read_number_of_subrectangles = true;
		}
		
		if ( !read_background_pixel_value )
		{
			background_pixel_value = rfb.readPixel();
			
			// Fill this section with the background color
			pixels.fillRect( pixels.rect, background_pixel_value );
		
			read_background_pixel_value = true;
		}
		
		while ( subrectanglesProcessed < number_of_subrectangles )
		{
			handleSubRect( rfb );

			// Reset flags
			read_subrect_pixel_value = false;
			xPosition = -1;
			yPosition = -1;
			width = -1;
			height = -1;

			// Move on to the next sub rectangle
			subrectanglesProcessed++;
		}
		
		// if we're done with our rectangles, hand control back to the parent
		return parent;
	}
	
	/**
	 * 
	 */
	override public function execute( screenImageData:BitmapData ):void
	{
		var container:RFBRectangle = RFBRectangle( parent );
		
		// Copy the pixel data to the screen image
		var dstPoint:Point = new Point( container.x, container.y );
		screenImageData.copyPixels( pixels, pixels.rect, dstPoint );
		
		// Free resources
		pixels.dispose();					  
		
	}
	
	private function handleSubRect( rfb:RFBProtocol ):void
	{
		if ( !read_subrect_pixel_value )
		{
			subrect_pixel_value = rfb.readPixel();
			read_subrect_pixel_value = true;
		}
		if ( xPosition == -1 )
		{
			xPosition = rfb.readU16();
		}
		if ( yPosition == -1 )
		{
			yPosition = rfb.readU16();
		}
		if ( width == -1 )
		{
			width = rfb.readU16();
		}
		if ( height == -1 )
		{
			height = rfb.readU16();
		}
		
		pixels.fillRect( new Rectangle( xPosition, yPosition, width, height ), 
						 subrect_pixel_value );
	}

} // end class
} // end package