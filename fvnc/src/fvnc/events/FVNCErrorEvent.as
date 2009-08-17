package fvnc.events
{
	import flash.events.ErrorEvent;

	/**
	 * 
	 */
	public class FVNCErrorEvent extends ErrorEvent
	{
		/** Static conast for the connection error event type. */
		public static const CONNECTION_ERROR:String = "connectionError";
		
		/**
		 * Constructor
		 */
		public function FVNCErrorEvent( type:String, bubble:Boolean = false, cancelable:Boolean = true, text:String = "" )
		{
			super( type, bubbles, cancelable, text );
		}
	}
}