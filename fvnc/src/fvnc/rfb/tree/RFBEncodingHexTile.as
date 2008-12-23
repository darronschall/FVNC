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

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.errors.EOFError;
import flash.geom.Point;
import flash.geom.Rectangle;

import fvnc.rfb.RFBProtocol;

/** 
 * Hextile encoding
 */
public class RFBEncodingHexTile extends RFBEncodingTileData
{
	/** The type of encoding for the tile */	
	private var subEncoding:int = -1;

	private var background:uint;
	private var readBackground:Boolean = false;
	
	private var foreground:uint;
	private var readForeground:Boolean = false;
	
	private var numberOfSubrectangles:int = -1;
	private var subrectanglesProcessed:int = 0;

	private var subrectPixelValue:uint = 0;
	private var readSubrectPixelValue:Boolean = false;
	
	/** Storage for the last x location when reading raw data */
	private var rawX:uint = 0;
	
	/** Storage for the last y location when reading raw data */
	private var rawY:uint = 0;
	
	private var xyPosition:int = -1;
	private var widthHeight:int = -1;
	

	/**
	 * Constructor
	 */
	public function RFBEncodingHexTile( parent:RFBRectangle )
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
		return doTiling( rfb, 16, 16 );
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

	override protected function handleTile( rfb:RFBProtocol, tileWidth:int, tileHeight:int ):void
	{
		// read the subencoding if we haven't yet
		if ( subEncoding == -1 )
		{
			subEncoding = rfb.readU8();
		}

		// Handle raw subencoding
		if ( subEncoding & 1 ) // HexTile.RAW
		{
			// Read in the raw pixel data
			for ( ; rawY < tileHeight; rawY++ )
			{
				for ( ; rawX < tileWidth; rawX++ )
				{
					pixels.setPixel( currentX + rawX, currentY + rawY, rfb.readPixel() );
				}
				rawX = 0;
			}
			rawY = 0;

			// Done, pass control back to the parent
			return;
		}

		// Check if we have a don't have background yet and if we need one, then 
		// get one if so
		if ( !readBackground )
		{
			if ( subEncoding & 2 ) // HexTile.BACKGROUND_SPECIFIED
			{
				background = rfb.readPixel();
			}
			readBackground = true;

			// Fill the rect with the background color
			pixels.fillRect( new Rectangle( currentX, currentY, tileWidth, tileHeight ), background );
		}

		// Check if we have a don't have foreground yet and if we need one, then 
		// get one if so
		if ( !readForeground )
		{
			if ( subEncoding & 4 ) // HexTile.FOREGROUND_SPECIFIED
			{
				foreground = rfb.readPixel();
			}
			readForeground = true;
		}

		// If we don't have subrectangles, hand control back to the parent
		if ( ( subEncoding & 8 ) == 0 ) // HexTile.ANY_SUBRECTS
		{
			return;
		}

		// Process the subrectangles
		if ( numberOfSubrectangles == -1 )
		{
			numberOfSubrectangles = rfb.readU8();
		}

		while ( subrectanglesProcessed < numberOfSubrectangles )
		{
			handleSubRect( rfb );

			subrectanglesProcessed++;
		}
	}

	override protected function finishTile( ):void
	{
		subrectanglesProcessed = 0;
		readBackground = false;
		readForeground = false;
		numberOfSubrectangles = -1;
		subEncoding = -1;
	}
	
	private function handleSubRect( rfb:RFBProtocol ):void
	{
		// If we have a different color, use that
		if ( !readSubrectPixelValue )
		{
			if ( subEncoding & 16 ) // HexTile.SUBRECTS_COLORED
			{
				subrectPixelValue = rfb.readPixel();
			}
			else
			{
				subrectPixelValue = foreground;
			}
			readSubrectPixelValue = true;
		}

		if ( xyPosition == -1 )
		{
			xyPosition = rfb.readU8();
		}

		if ( widthHeight == -1 )
		{
			widthHeight = rfb.readU8();
		}

		var fillX:uint = xyPosition >> 4;
		var fillY:uint = xyPosition & 0x0F;
		var fillWidth:uint = ( widthHeight >> 4 ) + 1;
		var fillHeight:uint = ( widthHeight & 0x0F ) + 1;

		// Fill the foreground color in
		pixels.fillRect ( new Rectangle( fillX + currentX, fillY + currentY, 
										 fillWidth, fillHeight ), 
						  subrectPixelValue );

		// Clear out our values
		readSubrectPixelValue = false;
		xyPosition = -1;
		widthHeight = -1;
	}
} // end class
} // end package
