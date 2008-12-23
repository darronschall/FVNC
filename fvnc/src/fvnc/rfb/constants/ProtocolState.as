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
package fvnc.rfb.constants
{	

/**
 * Constants for use in knowing what action needs to be
 * carried out during handshaking with the RFB server
 */
public class ProtocolState
{
	public static const NOT_CONNECTED:int = 0;
	public static const GET_AUTH_SCHEME:int = 1;
	public static const GET_CHALLENGE:int = 2;
	public static const GET_AUTH_RESULT:int = 3;
	public static const READ_SERVER_INIT:int = 4;
	public static const READ_SERVER_NAME:int = 5;
	
	/** Connected state means all of the handshaking is complete */
	public static const CONNECTED:int = 6;

} // end class
} // end package