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
 * Constants for use to decode the subendoing max for
 * Frame Buffer Updates using HexTile encoding
 */
public class HexTile
{
	public static const RAW:int = 1;
	public static const BACKGROUND_SPECIFIED:int = 2;
	public static const FOREGROUND_SPECIFIED:int = 4;
	public static const ANY_SUBRECTS:int = 8;
	public static const SUBRECTS_COLORED:int = 16;

} // end class
} // end package