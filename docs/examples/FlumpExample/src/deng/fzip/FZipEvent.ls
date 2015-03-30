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
	import deng.fzip.FZipFile;
	import loom2d.events.Event;

	/**
	 * FZip dispatches FZipEvent objects when a file contained in the
	 * ZIP archive has finished loading and can be accessed. There is 
	 * only one type of FZipEvent: FZipErrorEvent.FILE_LOADED.
	 */		
	public class FZipEvent extends Event
	{
		/**
		* The file that has finished loading.
		*/		
		public var file:FZipFile;
		
		/**
		* Defines the value of the type property of a FZipEvent object.
		*/		
		public static const FILE_LOADED:String = "fileLoaded";

		/**
		 * Constructor
		 * 
		 * @param type The type of the event. Event listeners can 
		 * access this information through the inherited type property. 
		 * There is only one type of FZipEvent: 
		 * FZipEvent.PARSE_ERROR.
		 * 
		 * @param file The file that has finished loading.
		 * 
		 * @param bubbles Determines whether the Event object participates 
		 * in the bubbling stage of the event flow. Event listeners can 
		 * access this information through the inherited bubbles property.
		 * 
		 * @param cancelable Determines whether the Event object can be 
		 * canceled. Event listeners can access this information through 
		 * the inherited cancelable property.
		 */		
		public function FZipEvent(type:String, file:FZipFile = null, bubbles:Boolean = false) {
			this.file = file;
			super(type, bubbles);
		}
		
		/**
		 * Creates a copy of the FZipEvent object and sets the value 
		 * of each property to match that of the original.
		 * 
		 * @return A new FZipEvent object with property values that 
		 * match those of the original.
		 */		
		override public function clone():Event {
			return new FZipEvent(type, file, bubbles);
		}
		
		/**
		 * TODO
		 * 
		 * @return String
		 */		
		override public function toString():String {
			return "[FZipEvent type=\"" + type + "\" filename=\"" + file.filename + "\" bubbles=" + bubbles + "]";
		}
	}
}