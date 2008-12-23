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
import fvnc.rfb.constants.Server;	

/**
 * The root node of the parse tree.  Corresponds to the given message type, which
 * are degined in the <code>rfb.constants.Server</code> class.
 * 
 * @see rfb.constants.Server
 */
public class RFBServerMessage extends RFBNode
{
	/** The message type being processed. One of the rfb.constants.Server values */
	private var messageType:int = 0;

	private var message:RFBNode;
	
	/**
	 * Constructor
	 */
	public function RFBServerMessage( parent:RFBNode )
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
		// Read the message type
		messageType = rfb.readByte();
		
		// Process the message
		switch ( messageType )
		{
			case 0: // Server.FRAMEBUFFER_UPDATE
				message = new RFBFrameBufferUpdate( this );
				break;
			
			case 2: // Server.BELL
				// Nothing more to read in the socket
				// TODO: Actually ring a bell here?  Can't from Flash Player, maybe we
				// play a soun though
				break;
			
			case 3: // Server.CUT_TEXT
				// TODO: Handle this better
				rfb.readServerCutText();
				break;
			
			default:
				// Uh oh, we don't handle this case
				throw new Error( "Unhandled message type: " + messageType );
		}
		
		return message;
	}
	
	/**
	 * 
	 */
	override public function execute( screenImageData:BitmapData ):void
	{
		if ( message )
		{
			message.execute( screenImageData );
		}
	}

} // end class
} // end package