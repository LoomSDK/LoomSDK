package poly.gameplay
{
   class Coin 
   {
      /**
       * Helper to generate random true/false values.
       */
      public static function flip():Boolean
      {
         return Math.round(Math.random()) < 0.5;
      }
   }
}