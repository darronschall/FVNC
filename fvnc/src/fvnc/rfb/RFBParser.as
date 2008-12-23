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
package fvnc.rfb
{

import flash.errors.EOFError;
import fvnc.rfb.tree.RFBNode;
import fvnc.rfb.tree.RFBServerMessage;

/**
 * This class parses the incoming RFB data from a socket.  It
 * gradially builds up a complete message.  If there is not
 * enough data to complete a message, it will pick up creating
 * the message from where it left off the next time parse()
 * is called.
 */
public class RFBParser
{
	/** The current server message being processed */
	private var serverMessage:RFBServerMessage;
	
	/** The node in the parse tree that is currently being processed */
	private var currentNode:RFBNode;
	
	/**
	 * The parse method is reponsible for looking at the RFB data and converting
	 * it into a list of server message.  It will return a list of all of
	 * the messages that could be built from the data available, or an empty Array
	 * if none could be built.  If there is not enough data to complete a message,
	 * the next time parse is called the processing will pick up from where it
	 * left off.
	 * 
	 * @return An array of RFBServerMessage
	 */
	public function parse( rfb:RFBProtocol ):Array
	{
		// The list of generated server messages
		var messages:Array = new Array(); // of RFBServerMessage
		
		// Wrap in a try catch block because there's a good chance we're going
		// to encounter an EOFError trying to parse a message.  Not a big deal,
		// we'll silenty trap the error, return, and then pick up where we left
		// off the next time parse is called.
		try
		{
			// Create messages until we get to the end of the buffer
			while ( true )
			{
				// Create the appropriate server message if we don't yet have one
				if ( serverMessage == null )
				{
					serverMessage = new RFBServerMessage( null );
					// Start at the top of the message and work our way down the tree
					currentNode = serverMessage;
				}
				
				// Continue building nodes until we get a null value, indicated that
				// a messaeg is complete
				while ( currentNode != null )
				{
					currentNode = currentNode.buildNode( rfb );
				}
				
				// Pushed the completed message on the message list, and try to complete
				// another message by setting message to null to start over
				messages.push( serverMessage );
				serverMessage = null;
			}
			
		}
		catch ( e:EOFError )
		{
			// Do nothing - we're expecting to run out of data
		}
		
		// Return the list of messages that we've successully parsed
		return messages;
	}
	
} // end class
} // end package