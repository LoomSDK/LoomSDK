package poly.gameplay
{
   import loom.gameframework.TickedComponent;

   /**
    * Component to manage a Poly's physical state (position, speed, size).
    */
   public class PolyMover extends TickedComponent
   {
      static public var BASE_RADIUS:Number = 36;
      static public var POLY_SPEED:Number = 120;

      public var x:Number = 0;
      public var y:Number = 0;
      public var scale:Number = 1;

      public var speedX:Number = 2.5;
      public var speedY:Number = 2.5;
      
      public var stopped:Boolean;

      public function PolyMover()
      {
         randomizeDirection();
      }

      public function positionRandomly():void
      {
         x = Math.random() * (960-128) + 64;
         y = Math.random() * (640-128) + 64;
      }

      public function randomizeDirection():void
      {
         var speedBudget:Number = POLY_SPEED;
         speedX = speedBudget * Math.random() + 0.5;
         speedY = speedBudget - speedX + 0.5;

         speedX *= Coin.flip() ? 1 : -1;
         speedY *= Coin.flip() ? 1 : -1;
      }

      public function onTick():void
      {
         if(stopped)
            return;

         var dt:Number = timeManager.TICK_RATE;
         x += speedX * dt;
         y += speedY * dt;

         var xMin:int = BASE_RADIUS * scale;
         var yMin:int = BASE_RADIUS * scale;
         var xMax:int = 950 - (BASE_RADIUS * scale);
         var yMax:int = 630 - (BASE_RADIUS * scale);

         if(x < xMin || x > xMax)
            speedX *= -1;

         if(y < yMin || y > yMax)
            speedY *= -1;
      }
   }
}