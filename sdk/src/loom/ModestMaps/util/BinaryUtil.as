/**
 * @author darren
 * $Id$
 */
package com.modestmaps.util
{
	public class BinaryUtil 
	{
		private static const PADDING:String = "00000000000000000000000000000000";
		
		/** 
		 * @return 32 digit binary representation of numberToConvert
		 *  
		 * NB:- don't use int.toString(2) here because it 
		 * doesn't do what we want with negative numbers - which is
		 * wrap around and pad with 1's. Hence convert to uint first. 
		 */
		public static function convertToBinary(numberToConvert:int):String 
		{
			var num:uint = numberToConvert; // should wrap around negatives
			var result:String = num.toString(2);
			if (result.length < 32) {
				result = PADDING.slice(result.length)+result;
			}
			return result;
		}
		
		public static function convertToDecimal(binaryRepresentation:String):int
		{
			// let Flash handle this one:
			return parseInt(binaryRepresentation, 2);
		}
	}
}