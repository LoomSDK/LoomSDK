package loom2d.math
{
    /**
     * A very simple Color class.
     * Also has helpful methods for converting different representations of colors.
     */
    public class Color
    {
        public var red:Number, green:Number, blue:Number, alpha:Number;

        /**
         * Allows easy creation of colors RGBA color representations.
         * @param r red value 0 - 255
         * @param g green value 0 - 255
         * @param b blue value 0 - 255
         * @param a alpha value 0 - 255
         */
        public function Color(r:Number = 0, g:Number = 0, b:Number = 0, a:Number = 255)
        {
            red = r;
            green = g;
            blue = b;
            alpha = a;
        }

        /**
         * Return the color as an integer representation, ie, 0 - 16777215.
         */
        public function toInt():Number
        {
            return (red << 16) + (green << 8) + blue;
        }

        /**
         * Return the color as a hex string representation, ie, #FF00FF.
         * @param prepend String to prepend to the beginning of the return value.
         * @return A hexidecimal representation of the color prepended with passed in prepend param.
         */
        public function toHex(prepend:String="#"):String
        {
            var n:Number = (red << 16) + (green << 8) + blue;
            return prepend + String.format("%06x", n).toUpperCase();
        }

        /**
         * @private
         */
        public function toString():String
        {
            return toHex();
        }

        /**
         * Decode a color from an integer, ie, 0xFF00FF.
         */
        [Deprecated(msg="Please use Color.fromInt instead.")]
        public static function fromInteger(value:int):Color
        {
            return fromInt(value);
        }

        /**
         * Decode a color from an integer, ie, 0xFF00FF.
         */
        public static function fromInt(value:int):Color
        {
            var r = (value >> 16) & 0xFF;
            var g = (value >> 8) & 0xFF;
            var b = value & 0xFF;

            return new Color(r,g,b);
        }

        /**
         * Decode a color from a hex string value, ie, #FF00FF.
         */
        public static function fromHex(value:String):Color
        {
            return fromInt(int("0x" + value.substr(1)));
        }

        /**
         * Returns a random color.
         */
        public static function random():Color
        {
            return fromInt(Math.floor(Math.random() * 16777215));
        }
    }   
}