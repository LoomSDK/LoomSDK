/**
 * @author darren
 * $Id$
 */
package com.modestmaps.util
{
	public class BinaryUtil 
	{
        private static const PADDING_0:String = "00000000000000000000000000000000";
		private static const PADDING_1:String = "11111111111111111111111111111111";
		
		/** 
		 * @return 32 digit binary representation of numberToConvert
		 *  
		 * NB:- don't use int.toString(2) here because it 
		 * doesn't do what we want with negative numbers - which is
		 * wrap around and pad with 1's.
         *
         * NOTE: Due to Loom not having unsigned int values, this will 
         * only work correctly for number with values up to up to 2147483647
		 */
		public static function convertToBinary(numberToConvert:int):String 
		{
            var negative:Boolean = false;       
            if(numberToConvert < 0)
            {
                //we want to wrap -ve values around as if we were casting to uint, so 2s comp FTW!
                numberToConvert += (1 << 30);
                negative = true;
            }

            //convert to a binary string
            var remainder:int;
            var result:String = "";
            while (numberToConvert > 0)
            {
                remainder = int(numberToConvert % 2);
                numberToConvert = int(numberToConvert / 2);
                result = remainder.toString() + result;
            }

            //add preceeding digits if necessary
			if (result.length < 32) 
            {
                var padding:String = (negative) ? PADDING_1 : PADDING_0;
                result = padding.slice(result.length)+result;
			}
			return result;
		}
		
		public static function convertToDecimal(binaryRepresentation:String):int
		{
            var decimalValue:int = 0;   
            var bitIndex:int = 0;
            var index:int = binaryRepresentation.length;
            while(index-- > 0)
            {
                //handle -ve values as Loom doesn't do unsigned ints
                if(bitIndex != 31)
                {
                    var bit:String = binaryRepresentation.charAt(index);
                    if(bit == "1")
                    {
                        decimalValue |= (1 << bitIndex);
                    }
                    bitIndex++;
                }
                else
                {
                    //2 comp FTW!
                    decimalValue -= (1 << 30);
                }
            }

            return decimalValue;
		}
	}
}