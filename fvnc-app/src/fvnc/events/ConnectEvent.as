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
package fvnc.events
{

import flash.events.Event;

/**
 * 
 */
public class ConnectEvent extends Event 
{
	/** Static constant for the event type. */
	public static const CONNECT:String = "connect";
	
	public var host:String;
	
	public var port:uint;
	
	public var fitToScreen:Boolean;
	
	/**
	 * Constructor
	 */
	public function ConnectEvent( host:String = "", port:uint = 0, fitToString:Boolean = false )
	{
		super( CONNECT );
		
		this.host = host;
		this.port = port;
		this.fitToScreen = fitToScreen;
	}
	
	/**
	 * Override clone to support re-dispatching
	 */
	override public function clone():Event
	{
		return new ConnectEvent( host, port );
	}

} // end class
} // end package