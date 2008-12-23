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
 * Class containing constants to be used in determing
 * what type of authentication to use to connect
 */
public class SecurityType
{
	public static const INVALID:int = 0;
	public static const NONE:int = 1;
	public static const VNC_AUTHENTICATION:int = 2;
	public static const RA2:int = 5;
	public static const RA2NE:int = 6;
	public static const TIGHT:int = 16;
	public static const ULTRA:int = 17;
	public static const TLS:int = 18;

} // end class
} // end package