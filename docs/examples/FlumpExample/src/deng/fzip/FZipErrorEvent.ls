/*
 * Copyright (C) 2006 Claus Wahlers and Max Herkender
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

package deng.fzip
{
	import loom2d.events.Event;

	/**
	 * FZip dispatches FZipErrorEvent objects when it encounters 
	 * errors while parsing the ZIP archive. There is only one type 
	 * of FZipErrorEvent: FZipErrorEvent.PARSE_ERROR
	 */		
	public class FZipErrorEvent extends Event
	{
		/**
		* A human readable description of the kind of parse error.
		*/		
		public var text:String;

		/**
		* Defines the value of the type property of a FZipErrorEvent object.
		*/		
		public static const PARSE_ERROR:String = "parseError";

		/**
		 * Constructor
		 * 
		 * @param type The type of the event. Event listeners can 
		 * access this information through the inherited type property. 
		 * There is only one type of FZipErrorEvent: 
		 * FZipErrorEvent.PARSE_ERROR.
		 * 
		 * @param text A human readable description of the kind of parse 
		 * error.
		 * 
		 * @param bubbles Determines whether the Event object participates 
		 * in the bubbling stage of the event flow. Event listeners can 
		 * access this information through the inherited bubbles property.
		 * 
		 * @param cancelable Determines whether the Event object can be 
		 * canceled. Event listeners can access this information through 
		 * the inherited cancelable property.
		 */		
		public function FZipErrorEvent(type:String, text:String = "", bubbles:Boolean = false) {
			this.text = text;
			super(type, bubbles);
		}
		
		/**
		 * Creates a copy of the FZipErrorEvent object and sets the value 
		 * of each property to match that of the original.
		 * 
		 * @return A new FZipErrorEvent object with property values that 
		 * match those of the original.
		 */		
		override public function clone():Event {
			return new FZipErrorEvent(type, text, bubbles);
		}
	}
}
