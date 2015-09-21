package feathers.utils
{
    public class FeathersMath
    {
        /**
         * Forces a numeric value into a specified range.
         * 
         * @param value        The value to force into the range.
         * @param minimum    The minimum bound of the range.
         * @param maximum    The maximum bound of the range.
         * @return            A value within the specified range.
         * 
         * @author Josh Tynjala (joshblog.net)
         */
        public static function clamp(value:Number, minimum:Number, maximum:Number):Number
        {
            if(minimum > maximum)
            {
                Debug.assert("minimum should be smaller than maximum.");
            }

            if(value > maximum)
                return maximum;
            if(value < minimum)
                return minimum;
            return value;
        }

        /**
         * Rounds a Number _up_ to the nearest multiple of an input. For example, by rounding
         * 16 up to the nearest 10, you will receive 20. Similar to the built-in function Math.ceil().
         * 
         * @param    numberToRound        the number to round up
         * @param    nearest                the number whose mutiple must be found
         * @return    the rounded number
         * 
         * @see Math#ceil
         */
        public static function roundUpToNearest(number:Number, nearest:Number = 1):Number
        {
            if(nearest == 0)
            {
                return number;
            }
            return Math.ceil(roundToPrecision(number / nearest, 10)) * nearest;
        }


        /**
         * Rounds a Number to the nearest multiple of an input. For example, by rounding
         * 16 to the nearest 10, you will receive 20. Similar to the built-in function Math.round().
         * 
         * @param    numberToRound        the number to round
         * @param    nearest                the number whose mutiple must be found
         * @return    the rounded number
         * 
         * @see Math#round
         */
        public static function roundToNearest(number:Number, nearest:Number = 1):Number
        {
            if(nearest == 0)
            {
                return number;
            }
            var roundedNumber:Number = Math.round(roundToPrecision(number / nearest, 10)) * nearest;
            return roundToPrecision(roundedNumber, 10);
        }

        /**
         * Rounds a number to a certain level of precision. Useful for limiting the number of
         * decimal places on a fractional number.
         * 
         * @param        number        the input number to round.
         * @param        precision    the number of decimal digits to keep
         * @return        the rounded number, or the original input if no rounding is needed
         * 
         * @see Math#round
         */
        public static function roundToPrecision(number:Number, precision:int = 0):Number
        {
            var decimalPlaces:Number = Math.pow(10, precision);
            return Math.round(decimalPlaces * number) / decimalPlaces;
        }

        /**
         * Rounds a Number _down_ to the nearest multiple of an input. For example, by rounding
         * 16 down to the nearest 10, you will receive 10. Similar to the built-in function Math.floor().
         * 
         * @param    numberToRound        the number to round down
         * @param    nearest                the number whose mutiple must be found
         * @return    the rounded number
         * 
         * @see Math#floor
         */
        public static function roundDownToNearest(number:Number, nearest:Number = 1):Number
        {
            if(nearest == 0)
            {
                return number;
            }
            return Math.floor(roundToPrecision(number / nearest, 10)) * nearest;
        }

        /**
         * Calculates a scale value to maintain aspect ratio and fill the required
         * bounds (with the possibility of cutting of the edges a bit).
         */
        public static function calculateScaleRatioToFill(originalWidth:Number, originalHeight:Number, targetWidth:Number, targetHeight:Number):Number
        {
            var widthRatio:Number = targetWidth / originalWidth;
            var heightRatio:Number = targetHeight / originalHeight;
            return Math.max(widthRatio, heightRatio);
        }

        /**
         * Calculates a scale value to maintain aspect ratio and fit inside the
         * required bounds (with the possibility of a bit of empty space on the
         * edges).
         */
        public static function calculateScaleRatioToFit(originalWidth:Number, originalHeight:Number, targetWidth:Number, targetHeight:Number):Number
        {
            var widthRatio:Number = targetWidth / originalWidth;
            var heightRatio:Number = targetHeight / originalHeight;
            return Math.min(widthRatio, heightRatio);
        }

    }
}