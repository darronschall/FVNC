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
import flash.geom.Point;
import flash.geom.Rectangle;

import fvnc.rfb.RFBProtocol;

/** 
 * FramebufferUpdate encoding 1 - CopyRect
 * Fields:
 * Bytes	Type	Description
 * 2		U16	src-x-position
 * 2		U16	src-y-position
 */
public class RFBEncodingCopyRect extends RFBEncodingData
{

	private var sourceX:int = -1;
	private var sourceY:int = -1;
	
	/**
	 * Constructor
	 */
	public function RFBEncodingCopyRect( parent:RFBRectangle )
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
		if ( sourceX == -1 )
		{
			sourceX = rfb.readU16();
		}

		if ( sourceY == -1 )
		{
			sourceY = rfb.readU16();
		}
	
		// Done reading data, pass control back to the parent
		return parent;
	}

	/**
	 * 
	 */
	override public function execute( screenImageData:BitmapData ):void
	{
		var container:RFBRectangle = RFBRectangle( parent );
		
		// Copy the data from one portion of the screen to another
		screenImageData.copyPixels( screenImageData, 
					new Rectangle( sourceX, sourceY, container.width, container.height ),
					new Point( container.x, container.y ) );
	}
	
} // end class
} // end package