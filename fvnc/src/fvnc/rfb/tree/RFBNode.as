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
 * The base class of all of the nodes in the RFB parse tree.
 */
public class RFBNode
{
	/** The parent of this node */
	protected var parent:RFBNode;
	
	/**
	 * Constructor
	 */
	public function RFBNode( parent:RFBNode )
	{
		this.parent = parent;
	}
	
	/**
	 * Create the node.  If the socket doesn't contain enough information, defer
	 * computation until later and raise an exception.
	 * 
	 * @return The next node to be processed or null if this message is complete
	 */
	public function buildNode( rfb:RFBProtocol ):RFBNode
	{
		// Subclasses should override
		return null;
	}
	
	/**
	 * 
	 */
	public function execute( screenImageData:BitmapData ):void
	{
		// Subclasses should override
	}

} // end class
} // end package