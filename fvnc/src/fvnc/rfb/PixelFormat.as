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

/**
 * A object describing the pixel format as specified by
 * the RFB spec.  Istead of using a generic object, we
 * create a class to speed up access to the pixel format
 * properties.  This gives us an added bonus of code completion
 * and better compile-time error checking.
 */
public class PixelFormat
{
	public var bitsPerPixel:int;
	public var depth:int;

	/** Determines how pixel values are read from the byte array */
	public var bigEndian:Boolean;

	public var trueColor:Boolean;
	public var redMax:int;
	public var greenMax:int;
	public var blueMax:int;
	public var redShift:int;
	public var greenShift:int;
	public var blueShift:int;

} // end class
} // end package