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

import fvnc.rfb.RFBProtocol;
import flash.display.BitmapData;

/**
 * 
 */
public class RFBEncodingTileData extends RFBEncodingData
{
	protected var pixels:BitmapData;

	/** x location for the current tile */
	protected var currentX:int = 0;

	/** y location for the current tile */
	protected var currentY:int = 0;

	/**
	 * Constructor
	 */
	public function RFBEncodingTileData( parent:RFBRectangle )
	{
		super( parent );
	}
	
	/**
	 * 
	 */
	protected function doTiling ( rfb:RFBProtocol, maxTileWidth:uint, maxTileHeight:uint ):RFBNode
	{
		var container:RFBRectangle = RFBRectangle( parent );
		while( true )
		{
			/* Calculate our remaining dimensions and if we have
			 * enough tiles, pass control back to our parent */
			if ( container.width - currentX <= 0 )
			{
				// start next row
				currentY += maxTileHeight;
				currentX = 0;
			}
			if ( container.height - currentY <= 0 )
			{
				// we're done
				return parent;
			}

			// Figure out the width and height for our tile
			var tileWidth:int = Math.min( maxTileWidth, container.width - currentX );
			var tileHeight:int = Math.min( maxTileHeight, container.height - currentY );

			handleTile( rfb, tileWidth, tileHeight );

			currentX += maxTileWidth;

			finishTile ( );
		}
		// We will never get here
		return null;
	}

	/**
	 * 
	 */
	protected function handleTile ( rfb:RFBProtocol, tileWidth:int, tileHeight:int ):void
	{
		// Override this in the subclass
	}

	/**
	 * 
	 */
	protected function finishTile ( ):void
	{
		// Override this in the subclass to clean up any loose ends necessary when you're done with a tile
	}
	
} // end class
} // end package