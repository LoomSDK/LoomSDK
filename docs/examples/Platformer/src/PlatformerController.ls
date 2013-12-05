package
{

  import loom.gameframework.AnimatedComponent;
  import loom.gameframework.TickedComponent;

  import loom2d.math.Point;
  import loom2d.math.Rectangle;


   /**
    * Component to move a Platformer object around based on rules or inputs
    */
   public class PlatformerController extends TickedComponent
   {
      private var mover:PlatformerMover;
      public var jumpSpeed = 10;
      private var canJump = true; // Internal flag to make you have to press the jump button every time you want to jump (rather than just holding it down)

      public var spriteFrame:String = "";
      public var scaleX:Number = 1;
      public var scaleY:Number = 1;

      public var moveFrames:Vector.<String> = [ "hero_run0.png", 
                                                "hero_run1.png",
                                                "hero_run2.png", 
                                                "hero_run3.png", 
                                                "hero_run4.png", 
                                                "hero_run5.png"];
      public var pixelsPerMoveFrame:int = 15;

      public var idleFrame:String = "hero_stand.png";

      public var jumpUpFrame:String = "hero_jump0.png";
      public var jumpDownFrame:String = "hero_jump1.png";

      public var wallSlideFrame:String = "hero_wall.png";

      public var facing:int;

      /**
       * Initialize a PlatformerMover directly from an object in a CCTMXObjectGroup loaded from a TMX
       */
      public function PlatformerController( _mover:PlatformerMover ) // tmxObj:CCDictionary)
      {
        mover = _mover;
      }

      override public function onTick():void
      {
        // Apply force based on inputs...
        if (Platformer.moveDirX == 0)
        {
          // If we're not holding down the stick, slow down.
          mover.velocityX = mover.velocityX * 0.75;
        }
        else
        {
          // Set the velocity gradually (this method works better for dpads)
          mover.velocityX += Platformer.moveDirX * 0.2;

          // Set the velocity instantly (this method works better for analog sticks)
//          mover.velocityX = Platformer.moveDirX * mover.velocityMaxX;

          facing = Platformer.moveDirX;
        }

        if(Platformer.jumpFlag && mover.onGround && canJump)
        {
            mover.velocityY -= jumpSpeed;
            canJump = false;
        }
        else
        {
          if (!Platformer.jumpFlag)
          {
            canJump = true;
          }
        }

        // Sprites

        // If we're on the ground
        if (mover.onGround)
        {
          if (mover.velocityX <  0.1 && 
              mover.velocityX > -0.1)
          {
            spriteFrame = idleFrame;
          }
          else
          {
            var moveFrame = Math.floor(mover.positionX / pixelsPerMoveFrame) % moveFrames.length;

            spriteFrame = moveFrames[moveFrame];
          }
        }
        else // Otherwise, we're in the air
        {
          if (mover.onWall)
          {
            spriteFrame = wallSlideFrame;
          }
          else if (mover.velocityY < 0)
          {
            spriteFrame = jumpUpFrame;
          }
          else
          {
            spriteFrame = jumpDownFrame;
          }
        }

        scaleX = (facing < 0) ? -1 : 1;

      }
   }
}