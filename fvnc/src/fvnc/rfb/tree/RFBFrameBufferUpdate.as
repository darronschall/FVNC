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
 * Message-type 0 - FrameBufferUpdate
 * fields:
 * Bytes	Type	Description
 * 1		U8	message-type
 * 1			padding
 * 2		U16	number-of-rectangles
 */
public class RFBFrameBufferUpdate extends RFBServerMessage
{
	/** Keep track of whether we absorbed the padding yet or not */
	private var readPadding:Boolean = false;
	
	/** The number of rectangles the server told us it would send */
	private var numberOfRectangles:uint = 0;
	
	/** Keep track of whether we read the rectangle count or not yet */
	private var readNumberOfRectangles:Boolean = false;
	
	/** Rectangles that we've received or started to receive thus far */
	[ArrayElementType("fvnc.rfb.RFBRectable")]
	private var rectangles:Array;
	
	/**
	 * Construtor.
	 */
	public function RFBFrameBufferUpdate( parent:RFBNode )
	{
		super( parent );
		
		rectangles = new Array();
	}
	
	/**
	 * Create the node.  If the socket doesn't contain enough information, defer
	 * computation until later and raise an exception.
	 * 
	 * @return The next node to be processed or null if this message is complete
	 */
	override public function buildNode( rfb:RFBProtocol ):RFBNode
	{
		// If we haven't yet, absorb the padding byte
		if ( !readPadding )
		{
			rfb.readByte();
			readPadding = true;
		}
		
		// If we haven't started yet, get the number of rectangles the server is sending to us
		if ( !readNumberOfRectangles )
		{
			numberOfRectangles = rfb.readU16();
			readNumberOfRectangles = true;
		}
		
		// If we already have enough rectangles, we're done so return null
		if ( rectangles.length == numberOfRectangles )
		{
			return null;
		}
		
		// If we don't have enough rectangles, create a new one, add it to our list and 
		// return it to be processed
		var rectangle:RFBRectangle = new RFBRectangle( this );
		rectangles.push( rectangle );
		
		return rectangle;
	}
	
	/**
	 * 
	 */
	override public function execute( screenImageData:BitmapData ):void
	{
		screenImageData.lock();
		
		for ( var i:int = 0; i < rectangles.length; i++ )
		{
			var rectangle:RFBRectangle = rectangles[i];
			rectangle.execute( screenImageData );
		}
		
		screenImageData.unlock();
	}

} // end class
} // end package