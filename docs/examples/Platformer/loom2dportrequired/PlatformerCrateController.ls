package
{

  import loom.gameframework.AnimatedComponent;
  import loom.gameframework.TickedComponent;
  import cocos2d.CCRect;
  import loom2d.math.Point;


   /**
    * Component to move a Platformer object around based on behavior as a pushable crate
    */
   public class PlatformerCrateController extends TickedComponent
   {
      private var mover:PlatformerMover;

      public var slideSpeed:Number = 2; // How fast the crate moves when pushed (per tick)
      public var snapX:Number = 32; // When pushing the crate it should snap to indices evenly divisible by this number

      public var pusherMask:Number = 0x01; // Mask of collidable objects that can push this crate

      private var destX:Number;

      /**
       * Initialize a PlatformerCrateController referencing a Mover
       */
      public function PlatformerCrateController( _mover:PlatformerMover ) // tmxObj:CCDictionary)
      {
        mover = _mover;
        destX = mover.positionX;
        mover.onCollideObject += handleOnCollideObj;
      }

      private function handleOnCollideObj(theObject:PlatformerMover, otherObject:PlatformerMover, resolution:PlatformerResolutionVector):void
      {
        if (mover.velocityX == 0)
        {
          if (otherObject.objectMask & pusherMask)
          {
            var dir = resolution.axis.x;

            destX = destX + dir * snapX;
          }
        }
      }

      override public function onTick():void
      {
        var dir = 0;
        var posX = mover.positionX;
        var deltaX = 0;

        if (posX > destX)
          dir = -1;
        else if (posX < destX)
          dir = 1;

        deltaX = dir * slideSpeed;

        // If we're sliding to the right, posX < destX
        /*
        if (dir > 0)
          if (posX + deltaX >= destX)
            deltaX = destX - posX;

        // If we're sliding to the left, posX > destX
        if (dir < 0)
          if (posX + deltaX <= destX)
            deltaX = posX - destX;
*/
        // TODO: Should these updates be done via bindings?  Or is direct modification okay?
        mover.velocityX = deltaX;
      }
   }
}