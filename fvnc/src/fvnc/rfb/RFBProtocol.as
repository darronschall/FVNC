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

import com.darronschall.utils.StringUtil;

import flash.events.*;
import flash.geom.Rectangle;
import flash.net.Socket;
import flash.ui.*;
import flash.utils.ByteArray;
import flash.utils.Endian;

import fvnc.errors.ConnectionError;
import fvnc.events.*;
import fvnc.rfb.constants.*;

/**
 * The RFBProtocol implements the RFB specification to connect
 * to a remote RFB server
 */
public class RFBProtocol extends Socket {

	/** The version supported */
	public static const version:String = "RFB 003.003" + String.fromCharCode( 10 );
	
	/** The port we're connecting on */
	private var port:uint;
	
	/** The host we're connecting to */
	private var host:String;
	
	/** The major version # of the RFB protocol supported */
	private var serverMajor:int;
	
	/** The minor version # of the RFB protocol supported */
	private var serverMinor:int;
	
	// =============================================================
	//  P I X E L    D A T A
	// =============================================================
	
	/** Store the number of bytes per pixel for reading pixel data */
	public var bytesPerPixel:uint;
	
	/** Determine how the pixel value is read (endian-ness is important!) */
	public var pixelEndian:String;

	/** The format that describes how the pixel data is encoded */
	private var pixelFormat:PixelFormat;
	
	/** Red value for color shift when calculating real pixel value */
	private var redShift:int;

	/** Green value for color shift when calculating real pixel value */
	private var greenShift:int;

	/** Blue value for color shift when calculating real pixel value */
	private var blueShift:int;

	/**
	 * Constructor, creates a new RFB socket connection to a host
	 * on a specific port.
	 */
	public function RFBProtocol( host:String, port:uint )
	{
		super( host, port );
		this.host = host;
		this.port = port;
	}
	
	/** Read only access to the major version for the RFB server */
	public function get majorVersion():int
	{
		return serverMajor;
	}
	
	/** Read only access to the minor version for the RFB server */
	public function get minorVersion():int
	{
		return serverMinor;
	}
		
	/**
	 * Reads the version information of the RFB protocol that the
	 * server supports.
	 */	
	public function readVersion():void
	{
		var b:ByteArray = new ByteArray();
		
		// Read 12 bytes from the socket and place in a byte array
		// to inspect.
		readBytes( b, 0, 12 );
		
		// Make sure we're connecting to an RFB server
		if (   b[0] != 82				// R
			|| b[1] != 70				// F
			|| b[2] != 66				// B
			|| b[3] != 32				// <spacee>
			|| b[4] < 48 || b[4] > 57	// digit 0-9
			|| b[5] < 48 || b[5] > 57	// digit 0-9
			|| b[6] < 48 || b[6] > 57	// digit 0-9
			|| b[7] != 46				// .
			|| b[8] < 48 || b[8] > 57	// digit 0-9
			|| b[9] < 48 || b[9] > 57	// digit 0-9
			|| b[10] < 48 || b[10] > 57	// digit 0-9
			|| b[11] != 10 )			// <newline>
		{			
			
			throw new Error("Host " + host + " port " + port + " is not an RFB server");
		}
		
		// Extract the version number from the string digitis
		serverMajor = (b[4] - 48) * 100 + (b[5] - 48) * 10 + (b[6] - 48);
		serverMinor = (b[8] - 48) * 100 + (b[9] - 48) * 10 + (b[10] - 48);
	}
	
	/**
	 * Writes the version of RFB that we'll be using to communicate with the server
	 */
	public function writeVersion():void
	{
		// Write the version information
		writeBytes( StringUtil.toByteArray( version ), 0, 12 );
		
		// After every write we need to flush() to ensure that the
		// data is sent across to the server
		flush();
	}
	
	/**
	 * Read the authentication required to start interacting with the server
	 */
	public function readAuthenticationScheme():int
	{
		var authScheme:int = readInt();
		
		// Determine the authentication scheme and act accordingly
		switch ( authScheme ) {
			case SecurityType.INVALID:
				// Invalid will give us a reason, so create a new ConnectionError
				// and raise the error to signal that a connection couldn't be made
				var reasonLength:int = readInt();
				var reason:ByteArray = new ByteArray();
				readBytes( reason, 0, reasonLength );
				
				throw new ConnectionError( reason.toString() );
				break;
			
			case SecurityType.NONE:
			case SecurityType.VNC_AUTHENTICATION:
				// Nothing extra to do here, just return the authentication scheme
				return authScheme;
				
			default:
				// Error - not sure what the server sent?
				throw new Error( "Unknown authentication scheme from RFB "
					+ "server: " + authScheme );
		}
	}
	
	/**
	 * For VNC Authentication, we're issued a 16 byte challenge that we
	 * need to encrypt with a password via DES and send back the encrypted
	 * version to the server to verify that the user can connect.  This
	 * method reads the challenge from the server.
	 *
	 * @return The authentication challenge issued by the server.
	 */
	public function readChallenge():ByteArray
	{
		var challenge:ByteArray = new ByteArray();
		readBytes( challenge, 0, 16 );
		return challenge;
	}
	
	/**
	 * Sends the authentication challenege (that was encrypted
	 * with a password) back to the server to verify that the user
	 * has the proper credentials to connect.
	 */
	public function writeChallenge( challenge:ByteArray ):void
	{
		// Write the 16 byte encrypted challenge
		writeBytes( challenge, 0, 16 );
		// Send the data off to the server
		flush();
	}
	
	/**
	 * Writes the client initialization to the server
	 *
	 * @param shareDesktop true if the server should share the desktop
	 *				and leave other clients connected.
	 */
	public function writeClientInit( shareDesktop:Boolean ):void
	{
		// Should the server try and share the desktop by
		// leaving other clients connected?  1 = yes, 0 = no
		writeByte( shareDesktop ? 1 : 0 );
		// Send the data off to the server
		flush();
	}
	
	/**
	 * Reads the initialization data from the server
	 */
	public function readServerInit():ServerInit
	{
		var serverInit:ServerInit = new ServerInit();
		pixelFormat = new PixelFormat();	
		
		serverInit.frameBufferWidth = readUnsignedShort();
		serverInit.frameBufferHeight = readUnsignedShort();
		
		// Read all of the data for the pixel format
		pixelFormat.bitsPerPixel = readByte();
		pixelFormat.depth = readByte();
		pixelFormat.bigEndian = Boolean( readByte() );
		pixelFormat.trueColor = Boolean( readByte() );
		pixelFormat.redMax = readUnsignedShort();
		pixelFormat.greenMax = readUnsignedShort();
		pixelFormat.blueMax = readUnsignedShort();
		pixelFormat.redShift = readByte();
		pixelFormat.greenShift = readByte();
		pixelFormat.blueShift = readByte();
		
		// Calculate values needed to display the correct colors
		calculateColors( pixelFormat );
		
		// skip over padding
		readByte();
		readByte();
		readByte();
		
		// Read the length of the server name
		serverInit.nameLength = readInt();
		
		return serverInit;
	}
	
	public function readServerName( nameLength:int ):String
	{
		// Read the name of the server we're connected to
		var name:ByteArray = new ByteArray();
		readBytes( name, 0, nameLength );
		
		return name.toString();
	}
	
	public function readU8():uint
	{
		return readUnsignedByte();
	}

	public function readU16():uint
	{
		return readUnsignedShort();
	}

	public function readS32():int
	{
		return readInt();
	}
	
	public function readU32():int
	{
		return readUnsignedInt();
	}

	/**
	 * Reads the pixel data for a raw encoded frame buffer
	 * update message.
	 */
	public function readPixel():uint
	{
		//var bytes:ByteArray = new ByteArray();
		//readBytes( bytes, 0, bytesPerPixel );
		//bytes.endian = pixelEndian;
		switch ( bytesPerPixel ) 
		{
			case 1: return convertPixelData( readByte() );
			case 2: return convertPixelData( readShort() );
			case 4: return convertPixelData( readInt() );
			default:
				throw new Error( "Invalid bytesPerPixel: " + bytesPerPixel );
		}
	}
	
	/**
	 * Calculate color values, the amount we need to shift by in order to
	 * display the pixel data correctly.
	 */
	private function calculateColors( pixelFormat:PixelFormat ):void
	{
		var t:int = 0;
		for ( t = 0; t < 32; t++ )
		{
			if ( ( ( 1 << t ) & pixelFormat.redMax ) == 0 )
			{
				break;
			}
		}
		redShift = 24 - t;
		
		for ( t = 0; t < 32; t++ )
		{
			if ( ( ( 1 << t ) & pixelFormat.greenMax ) == 0 )
			{
				break;
			}
		}
		greenShift = 16 - t;
		
		for ( t = 0; t < 32; t++ )
		{
			if ( ( ( 1 << t ) & pixelFormat.blueMax ) == 0 )
			{
				break;
			}
		}
		blueShift = 8 - t;
	}
	
	/**
	 * Based on the pixelFormat, this method will convert the
	 * data for a pixel into an actual RGB color value to display.
	 */
	private function convertPixelData( data:uint ):uint
	{
		if ( pixelFormat.trueColor )
		{
			return ( ( ( data >> pixelFormat.redShift ) & pixelFormat.redMax ) << redShift )
				| ( ( ( data >> pixelFormat.greenShift ) & pixelFormat.greenMax ) << greenShift )
				| ( ( ( data >> pixelFormat.blueShift ) & pixelFormat.blueMax ) << blueShift )
		}
		
		// TODO: Need to handle this case when true color isn't used
		return 0;
	}
	
	/**
	 * Reads a color entry from the server
	 *
	 * @return An object with the following properties:
	 *		red		int
	 *		green	int
	 *		blue	int
	 */
	public function readColorEntry():Object
	{
		var o:Object = new Object();
		o.red = readUnsignedShort();
		o.green = readUnsignedShort();
		o.blue = readUnsignedShort();
		return o;
	}
	
	/**
	 * Reads a server cut text message from the server
	 *
	 * @return The string that was cut
	 */
	public function readServerCutText():String
	{
		// skip padding
		readByte();
		readByte();
		readByte();
		
		var length:uint = readUnsignedInt();
		var text:ByteArray = new ByteArray();
		readBytes( text, 0, length );
		return text.toString();
	}
	
	/**
	 * Sets the format in which pixel values should be sent in 
	 * FrameBufferUpdate messages.
	 */
	public function writeSetPixelFormat( pixelFormat:PixelFormat ):void
	{
		this.pixelFormat = pixelFormat;
		bytesPerPixel = pixelFormat.bitsPerPixel / 8;
		pixelEndian = pixelFormat.bigEndian ? Endian.BIG_ENDIAN : Endian.LITTLE_ENDIAN;
		
		// Calculate values needed to display the correct colors
		calculateColors( pixelFormat );
		
		// Let the server know what kind of message is coming from the client
		writeByte( Client.SET_PIXEL_FORMAT );

		// padding
		writeByte( 0 );
		writeByte( 0 );
		writeByte( 0 );
		
		// Write the pixel format data in the socket
		writeByte( pixelFormat.bitsPerPixel );
		writeByte( pixelFormat.depth );
		writeByte( pixelFormat.bigEndian ? 1 : 0 );
		writeByte( pixelFormat.trueColor ? 1 : 0 );
		writeShort( pixelFormat.redMax );
		writeShort( pixelFormat.greenMax );
		writeShort( pixelFormat.blueMax );
		writeByte( pixelFormat.redShift );
		writeByte( pixelFormat.greenShift );
		writeByte( pixelFormat.blueShift );
		
		// Write padding
		writeByte( 0 );
		writeByte( 0 );
		writeByte( 0 );
		
		// Send the data off to the server
		flush();
	}
	
	/**
	 * Sets the encoding types in which pixel data can be sent by 
	 * the server. The order of the encoding types given in this message
	 * is a hint by the client as to its preference (the first encoding
	 * specified being most preferred). The server may or may not choose
	 * to make use of this hint. Pixel data may always be sent in raw 
	 * encoding even if not specified explicitly here.
	 *
	 * @param encodings An array of int corresponding to values
	 *		in the <code>Encoding</code> class.
	 */
	public function writeSetEncodings( encodings:Array ):void
	{
		// Let the server know what kind of message is coming from the client
		writeByte( Client.SET_ENCODINGS );
		
		// Write padding
		writeByte( 0 );
		
		// Let the server know the number of encodings being used
		var length:uint = encodings.length;
		writeShort( length  );
		
		// Write out all of the encodings that are supported
		for ( var i:uint = 0; i < length; i++ )
		{
			writeInt( encodings[i] );
		}
		
		// Send the data off to the server
		flush();
	}
	
	/**
	 * Request a certain area of the screen to be refreshed from the server
	 * so the client can draw it correctly.
	 *
	 * @param rect The rectangular area that the client wants to draw
	 * @param incremental If true, the server will only send changes since the
	 *				last frame buffer update request.  When false, the server
	 *				sends the entire contents of the rect.
	 */
	public function writeFrameBufferUpdateRequest( rect:Rectangle, incremental:Boolean = true ):void
	{
		// Let the server know what kind of message is coming from the client
		writeByte( Client.FRAMEBUFFER_UPDATE_REQUEST );
		
		writeByte( incremental ? 1 : 0 );
		
		// Write the rectangle area that the client wants updated from the server
		writeShort( rect.x );
		writeShort( rect.y );
		writeShort( rect.width );
		writeShort( rect.height );
		
		// Send the data off to the server
		flush();
	}
	
	/**
	 * Indicate that a key was pressed on the client
	 */
	public function writeKeyDownEvent( event:KeyboardEvent ):void {
		// Control and Shift are special - these are written via the
		// key modified, so if the key that was pressed is control or
		// shift, then ignore it.  This isn't a perfect implementation
		// (pressing and releasing control on the client should press
		// and release control on the server...) but seems to work alright
		// nonetheless.
		if ( event.keyCode == Keyboard.CONTROL || event.keyCode == Keyboard.SHIFT )
		{
			return;
		}
		
		// Handle sending modifiers as a separate key press
		writeKeyModifiers( event );
		
		// Get the keySym value based on the key pressed
		var keysym:uint = getKeySym( event );
		// Write the key event into the socket and note it was a key down
		writeKeyEvent( keysym, true );
		
		// Send the data off to the server
		flush();
	}
	
	/**
	 * Indicate that a key was released on the client
	 */
	public function writeKeyUpEvent( event:KeyboardEvent ):void
	{
		// Control and Shift are special - these are written via the
		// key modified, so if the key that was pressed is control or
		// shift, then ignore it.  This isn't a perfect implementation
		// (pressing and releasing control on the client should press
		// and release control on the server...) but seems to work alright
		// nonetheless.
		if ( event.keyCode == Keyboard.CONTROL || event.keyCode == Keyboard.SHIFT )
		{
			return;
		}
		
		// Handle sending modifiers as a separate key press
		writeKeyModifiers( event );
		
		// Get the keySym value based on the key pressed
		var keysym:uint = getKeySym( event );
		// Write the key event into the socket and note it was a key up
		writeKeyEvent( keysym, false );
					
		// Send the data off to the server
		flush();
	}
	
	/**
	 * Write the key modifiers to the server, which include control,
	 * shift, alt,  and indicate if the left or right one was
	 * pressed.
	 */
	private function writeKeyModifiers( event:KeyboardEvent ):void
	{
		if ( event.shiftKey )
		{
			// Determine which shift key was pressed
			writeKeyEvent( event.keyLocation == KeyLocation.LEFT ? 0xFFE1 : 0xFFE2, false );	
		}
		else if ( event.ctrlKey )
		{
			// Determine which control key was pressed
			writeKeyEvent( event.keyLocation == KeyLocation.LEFT ? 0xFFE3 : 0xFFE4, false );	
		}
		else if ( event.altKey )
		{
			// Determine which alt key was pressed
			writeKeyEvent( event.keyLocation == KeyLocation.LEFT ? 0xFFE9 : 0xFFEA, false );	
		}
	}
	
	/**
	 * Returns the keysym value based on the key that was pressed
	 * (or released) as indicated by the KeyboardEvent.
	 */
	private function getKeySym( event:KeyboardEvent ):uint
	{
		var keysym:uint;
		
		keysym = event.keyCode;
		
		// Check for the common keys and convert their keysym values
		switch ( keysym ) {
			case Keyboard.BACKSPACE : keysym = 0xFF08; break;
			case Keyboard.TAB       : keysym = 0xFF09; break;
			case Keyboard.ENTER     : keysym = 0xFF0D; break;
			case Keyboard.ESCAPE    : keysym = 0xFF1B; break;
			case Keyboard.INSERT    : keysym = 0xFF63; break;
			case Keyboard.DELETE    : keysym = 0xFFFF; break;
			case Keyboard.HOME      : keysym = 0xFF50; break;
			case Keyboard.END       : keysym = 0xFF57; break;
			case Keyboard.PAGE_UP   : keysym = 0xFF55; break;
			case Keyboard.PAGE_DOWN : keysym = 0xFF56; break;
			case Keyboard.LEFT   	: keysym = 0xFF51; break;
			case Keyboard.UP   		: keysym = 0xFF52; break;
			case Keyboard.RIGHT   	: keysym = 0xFF53; break;
			case Keyboard.DOWN   	: keysym = 0xFF54; break;
			case Keyboard.F1   		: keysym = 0xFFBE; break;
			case Keyboard.F2   		: keysym = 0xFFBF; break;
			case Keyboard.F3   		: keysym = 0xFFC0; break;
			case Keyboard.F4   		: keysym = 0xFFC1; break;
			case Keyboard.F5   		: keysym = 0xFFC2; break;
			case Keyboard.F6   		: keysym = 0xFFC3; break;
			case Keyboard.F7   		: keysym = 0xFFC4; break;
			case Keyboard.F8   		: keysym = 0xFFC5; break;
			case Keyboard.F9   		: keysym = 0xFFC6; break;
			case Keyboard.F10  		: keysym = 0xFFC7; break;
			case Keyboard.F11  		: keysym = 0xFFC8; break;
			case Keyboard.F12  		: keysym = 0xFFC9; break;
			
			default:
				// If not one of the keys above, use the charCode
				// which will differentiate between 'A' and 'a' when
				// sending "the a key was pressed" to the server.
				keysym = event.charCode;
		}
		
		return keysym;	
	}
	
	/**
	 * Indicate that a key was pressed or released
	 * on the client.
	 */
	private function writeKeyEvent( keysym:uint, down:Boolean ):void {
		// Let the server know what kind of message is coming from the client
		writeByte( Client.KEY_EVENT );
		
		writeByte( down ? 1 : 0 );
		
		// Write padding
		writeByte( 0 );
		writeByte( 0 );
		
		writeUnsignedInt( keysym );
		
		// Send the data off to the server
		flush();
	}
	
	/**
	 * Write either pointer movement or interaction
	 * to the server.
	 */
	public function writePointerEvent( event:MouseEvent ):void
	{
		// Let the server know what kind of message is coming from the client
		writeByte( Client.POINTER_EVENT );
		
		var pointerMask:uint = 0;
		
		// Check for the left mouse button being down
		if ( event.buttonDown )
		{
			pointerMask = 1;
		}
		// TODO: What do we do about middle and right mouse button?
		
		// Check for Mouse Scroll
		if ( event.delta < 0 )
		{
			// scroll down - button "5"
			pointerMask |= 0x10;
		}
		else if ( event.delta > 0 )
		{
			// scroll up - button "4"
			pointerMask |= 0x04;
		}
		
		writeByte( pointerMask );
		
		// Write the location of the mouse pointer, which is 
		// simply the local x and y location in the remoteScreen that
		// generated the event.
		writeShort( event.localX + 1 );
		writeShort( event.localY + 1 );
		
		// Send the data off to the server
		flush();
	}
	
	/**
	 * Let the server know that the client has new
	 * text in the clipboard.
	 */
	public function writeClientCutText( text:String ):void
	{
		// Let the server know what kind of message is coming from the client
		writeByte( Client.CUT_TEXT );
		
		// 3 bytes padding
		writeByte( 0 );
		writeByte( 0 );
		writeByte( 0 );
		
		// length
		writeUnsignedInt( text.length );
		// Can't write UTF bytes as this is not supported by RFB
		//writeUTFBytes( text );
		
		// Convert the string to an array of bytes to write
		var textBytes:ByteArray = new ByteArray();
		for ( var i:uint = 0; i < text.length; i++ )
		{
			textBytes.writeByte( text.charCodeAt( i ) );
		}
		writeBytes( textBytes );
		
		// Send the data off to the server
		flush();
	}
	
} // end class
} // end package