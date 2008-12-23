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
package fvnc.errors
{

/**
 * A connection error is used to signal that something went wrong
 * with authentication to the RFB server, and captures the specific
 * message.
 */
public class ConnectionError extends Error 
{
	
	/**
	 * Constructor, creates a new connection error with a specific 
	 * message.
	 */
	public function ConnectionError( message:String )
	{
		super( message );
	}

} // end class
} // end package