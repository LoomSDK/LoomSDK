package
{
  import loom2d.tmx.TMXLayer;

  import loom.gameframework.AnimatedComponent;
  import loom.gameframework.TickedComponent;
  
  import loom2d.math.Point;
  import loom2d.math.Rectangle;
  
  import loom.gameframework.TimeManager;

   delegate PlatformerMoverTileCollisionCallback(theObject:PlatformerMover, gid:int, tileX:int, tileY:int, mapLayer:TMXLayer, resolution:PlatformerResolutionVector):void;
   delegate PlatformerMoverObjectCollisionCallback(theObject:PlatformerMover, otherObject:PlatformerMover, resolution:PlatformerResolutionVector):void;
   delegate PlatformerMoverTriggerContactCallback(theObject:PlatformerMover, otherObject:PlatformerMover):void;

   /**
    * Component to manage an Platformer object's position, collision size, forces, and flags
    */
   public class PlatformerMover extends TickedComponent
   {
      public var manager:PlatformerMoverManager;

      /**
       * Position of the object, X
       */
      public var positionX:Number = 0;
      /**
       * Position of the object, Y
       */
      public var positionY:Number = 0;

      /**
       * Velocity of the object, X
       */
      public var velocityX:Number = 0;
      /**
       * Velocity of the object, Y
       */
      public var velocityY:Number = 0;

      /**
       * The size of the PlatformObject used for collisions, X.
       * 
       * Useful if the collision size of the object is different from the rendering size of the object.
       */
      public var solidSizeX:Number = 32;

      /**
       * The size of the PlatformObject used for collisions, X.
       * 
       * Useful if the collision size of the object is different from the rendering size of the object.
       */
      public var solidSizeY:Number = 32;

      /**
       * The constant force applied to the object each tick, X.
       */
      public    var gravityX:Number = 0;
      /**
       * The constant force applied to the object each tick, Y.
       */
      public    var gravityY:Number = 0.5;

      /**
       * The 'bounciness' of the object -- 0 to 1
       */
      public    var bounceFactor:Number = 0;
        
      /**
       * Minimum downward velocity to trigger a bounce.
       */
      public    var bounceMinimum:Number = 2;
        
      public    var airResistance:Number = 0;
      public    var friction:Number      = 0;
        
      /**
       * The maximum velocity that the object should be able to have in any given tick, X
       * 
       * If this is set too high, it is possible for objects to go through each other in the game world.
       * 
       * As such, a good rule of thumb is to keep this under the tile size used for the game world.
       */
      public    var velocityMaxX:Number = 5;
      /**
       * The maximum velocity that the object should be able to have in any given tick, Y
       * 
       * If this is set too high, it is possible for objects to go through each other in the game world.
       * 
       * As such, a good rule of thumb is to keep this under the tile size used for the game world.
       */
      public    var velocityMaxY:Number = 10;

      /**
       * If true, this object is clamped from going outside the left boundary of its tile map(s).
       */
      public    var clampMapLeft:Boolean   = true;
      /**
       * If true, this object is clamped from going outside the right boundary of its tile map(s).
       */
      public    var clampMapRight:Boolean  = true;
      /**
       * If true, this object is clamped from going outside the top boundary of its tile map(s).
       */
      public    var clampMapTop:Boolean    = false;
      /**
       * If true, this object is clamped from going outside the bottom boundary of its tile map(s).
       */
      public    var clampMapBottom:Boolean = false;
        
      /**
       * Whether or not this object should phsyically resolve collisions with the world.  Beware setting this to "false" -- if any gravity is set, the object will fall through the world geometry.
         * 
         * If this is "false", Trigger events can still fire.
       */
      public    var solid:Boolean  = true; 
      
      /**
       * If this object should only have collisions with other objects from the top edge, and not the sides or bottom.
       */
      public    var oneWay:Boolean = false;
      
      /**
       * Whether or not the object is fixed in space, or if it can be move.
       */
      public    var fixed:Boolean  = false;

      /**
       * An internal flag that can help us shortcut a lot of processing.  
       * 
       * When true, this object will be ignored from many gravity and world geometry calculations.
       */
      public function get atRest():Boolean
      {
        return _atRest;
      }
      protected  var _atRest:Boolean = false;
    
      /**
       * This can be set to true to make sure an object is not at rest.
       */
      public var bumped:Boolean = false;
        
      /**
       * This is the slope of the tile or object that the object is resting on (if any)
       */ 
      public var collisionSlope:Number = 0;
        
      /**
       * Internal flag usable by descending controller classes.
       * 
       * Whether or not the object is on the ground or another object.
       */
      public var onGround:Boolean = false;
    
      /**
       * Internal flag usable by descending controller classes.
       * 
       * 0 for no wall contact, -1 for left wall, 1 for right wall
       */
      public  var onWall:int = 0;

      public var collidesWithObjectMask:int = 0xff;
      public var objectMask:int = 0xff;
    
      public var onCollideObject:PlatformerMoverObjectCollisionCallback;
      public var onCollideTile:PlatformerMoverTileCollisionCallback;

      /**
       * Internal flag usable by descending controller classes.
       * 
       * 0 for no cliff adjacency, -1 for a cliff to the left, 1 for cliff to the right
       */
      public function get onCliff():int
      {
          return _onCliff;
      }
      protected  var _onCliff:int = 0;            
    
      /**
       * The state of onGround _last_ frame.
       */
      protected  var wasOnGround:Boolean = false;

      /**
       * The state of onCliff _last_ frame.
       */
      protected  var wasOnCliff:int = 0;

      /**
       * The state of onWall _last_ frame.
       */
      protected  var wasOnWall:int = 0;


      public var dest:Rectangle = new Rectangle();

      /**
       * Initialize a PlatformerMover directly from an object in a CCTMXObjectGroup loaded from a TMX
       */
      public function PlatformerMover( x:Number, y:Number, moverManager:PlatformerMoverManager ) // tmxObj:CCDictionary)
      {
         // TODO:
         positionX = x;
         positionY = y;

        // HACK TO WORK AROUND PROBLEM WITH Point
        AXIS_RIGHT.x = 1;
        AXIS_RIGHT.y = 0;
        AXIS_LEFT.x = -1;
        AXIS_LEFT.y = 0;
        AXIS_DOWN.x = 0;
        AXIS_DOWN.y = 1;
        AXIS_UP.x = 0;
        AXIS_UP.y = -1;
        // END HACK


         manager = moverManager;
      }

      /**
       * Executed when this renderer is added. It create a sprites and sets the correct texture for it.
       *
       * @return  Boolean Returns true if the sprite was successfully added to the sprite batch.
       */
      protected function onAdd():Boolean
      {
         if(!super.onAdd())
             return false;
         /*

         frame = CCSpriteFrameCache.sharedSpriteFrameCache().spriteFrameByName(texture);
         if (!frame)
             return false;

         sprite = CCSprite.createWithSpriteFrame(frame);
         game.layer.addChild(sprite);
*/
        if (manager != null)
          manager.platformerObjectList.push(this);

         return true;
      }

      /**
       * This is meant to remove the sprite from the main layer.
       */
      protected function onRemove():void
      {
//         game.layer.removeChild(sprite);
        manager.platformerObjectList.remove(this);

        super.onRemove();
      }

      override public function onTick():void
      {
        // Initialize

        wasOnGround = onGround;
        wasOnWall = onWall;
        wasOnCliff = onCliff;

        onGround = false;
        onWall = 0;
        _onCliff = 0;

        // Acceleration due to gravity
        velocityY += gravityY;
        velocityX += gravityX;

        // Clamp velocity to min / max
        velocityX = Math.clamp( velocityX, 0-velocityMaxX, velocityMaxX );
        velocityY = Math.clamp( velocityY, 0-velocityMaxY, velocityMaxY );

        // Set the destination position for this frame
        var xdir:int = velocityX > 0 ? 1 : velocityX < 0 ? -1 : 0; 
        var ydir:int = velocityY > 0 ? 1 : velocityY < 0 ? -1 : 0;

        // Find the new desired location for this frame
        dest.setTo(topLeftX + velocityX, topLeftY + velocityY, solidSizeX, solidSizeY);
//        Console.print("Setting dest to (" + (topLeftX + velocityX) + "," + (topLeftY + velocityY) + "," + solidSizeX + "," + solidSizeY + ")");
//        Console.print("Plat dest rect: (" + dest.x + "-" + dest.right + "," + dest.y + "-" + dest.bottom + ")");


        // Query the spatial manager to test the new position against other world objects
        manager.collide( this );

        // Finalize

        positionX = dest.x + dest.width * 0.5; 
        positionY = dest.y + dest.height * 0.5;

        // Decelerate due to friction
        if (onWall != 0 || onGround)
        {
          velocityX = velocityX * (1 - friction);
          velocityY = velocityY * (1 - friction);
        } else {
          velocityX = velocityX * (1 - airResistance);
          velocityY = velocityY * (1 - airResistance);
        }
      }

        private static const V_RIGHT:int = 0;
        private static const V_LEFT :int = 1;
        private static const V_DOWN :int = 2;
        private static const V_UP   :int = 3;
        
        private static const AXIS_RIGHT:Point = new Point( 1,  0);
        private static const AXIS_LEFT :Point = new Point(-1,  0);
        private static const AXIS_DOWN :Point = new Point( 0,  1);
        private static const AXIS_UP   :Point = new Point( 0, -1);
        
        protected var resolutions:Vector.<PlatformerResolutionVector> = [
            new PlatformerResolutionVector(AXIS_RIGHT),
            new PlatformerResolutionVector(AXIS_LEFT),
            new PlatformerResolutionVector(AXIS_DOWN),
            new PlatformerResolutionVector(AXIS_UP)
        ];
        
        public function contactVsObj( obj:PlatformerMover ):Boolean {
            if (!solid || !obj.solid || !(obj.collidesWithObjectMask & this.objectMask))
                return false;
            
            var bounds:Rectangle      = this.bounds;
            var otherBounds:Rectangle = obj.dest;
            
            return rectsOverlap( bounds, otherBounds );
        }
        
        public function collideVsObj( obj:PlatformerMover ):Boolean
        {
            if (!solid || !obj.solid || !(obj.collidesWithObjectMask & this.objectMask))
                return false;
            
            var thisBounds:Rectangle      = this.bounds;
            var objBounds:Rectangle = obj.dest;
            
            if (!rectsOverlap(thisBounds,objBounds))
                return false;
            
            resolutions[V_RIGHT].distance =   thisBounds.right   - objBounds.x;
            resolutions[V_LEFT].distance  =   objBounds.right   - thisBounds.x;
            resolutions[V_DOWN].distance  =   thisBounds.bottom  - objBounds.y;
            resolutions[V_UP].distance    =   objBounds.bottom  - thisBounds.y;

            resolutions[V_RIGHT].enabled  = true;
            resolutions[V_LEFT].enabled   = true;
            resolutions[V_DOWN].enabled   = true;
            resolutions[V_UP].enabled     = true;

            
            // Disqualify vectors based on whether or not we're one-way
            if (oneWay) {
                resolutions[V_RIGHT].enabled = false;
                resolutions[V_LEFT].enabled = false;
                resolutions[V_DOWN].enabled = false;
                
                if (obj.bounds.bottom > bounds.y)
                    resolutions[V_UP].enabled = false;
            }
            
            // Find the minimum collision resolution vector
            var minRes:int = -1;
            for (var cnt:int = 0; cnt < 4; cnt++) {
                if (resolutions[cnt].enabled) {
                    if (minRes == -1)
                        minRes = cnt;
                    
                    if (resolutions[cnt].distance < resolutions[minRes].distance)
                        minRes = cnt;
                }
            }
            
            // Give preference to the "up" axis if beneath a certain threshold:
            // This helps keep from snagging on corners
            //*
            if (minRes == V_LEFT || minRes == V_RIGHT) {
                if (resolutions[V_UP].enabled) {
                    //                    if (resolutions[V_UP].distance - resolutions[minRes].distance <= (Math.abs(obj.velocityY) + Math.abs(obj.velocityX))) {
                    //                    if ( Math.abs( resolutions[V_UP].distance - obj.velocityY ) <= Math.abs( resolutions[minRes].distance - obj.velocityX )) {
                    if ( resolutions[V_UP].distance <= (resolutions[minRes].distance + Math.abs(obj.velocityX) + Math.abs(obj.velocityY))) {
                        minRes = V_UP;
                    }
                } else if (resolutions[V_DOWN].enabled) {
                    //                    if (resolutions[V_DOWN].distance - resolutions[minRes].distance <= (Math.abs(obj.velocityY) + Math.abs(obj.velocityX))) {
                    //                    if ( Math.abs( resolutions[V_DOWN].distance - obj.velocityY ) <= Math.abs( resolutions[minRes].distance - obj.velocityX )) {
                    if ( resolutions[V_DOWN].distance <= (resolutions[minRes].distance + Math.abs(obj.velocityX) + Math.abs(obj.velocityY))) {
                        minRes = V_DOWN;
                    }
                }
            } //*/

            
//            Console.print("Minimum object-to-object resolution vector is " + minRes);

            // If there is a valid resolution direction...
            if (minRes != -1) {
                //resolutions[minRes]
                var res:PlatformerResolutionVector = resolutions[minRes];
                
                if (obj.onCollideObject != null)
                {
                  // Duplicate the vector in case this is modified later
                  var r2:PlatformerResolutionVector = res.dupe();
                  timeManager.callLater( fireCollideObj, [ obj, this, r2 ] );
                }

                // TODO: Contact events
                // PBE.processManager.callLater( triggerContactEvent, [res, obj, this] );
                
                // Then collide!

                // Resolve the collisions
                obj.dest.x += res.axis.x * res.distance;
                obj.dest.y += res.axis.y * res.distance;

                // TODO: Store the overlap

                // If we won't respond to the other object's collisions, then make them absorb our momentum
                if (!(this.collidesWithObjectMask & obj.objectMask))
                {
                    if ((res.axis.x < 0 && obj.velocityX > this.velocityX ) ||
                        (res.axis.x > 0 && obj.velocityX < this.velocityX))
                        obj.velocityX = this.velocityX;
                    if ((res.axis.y < 0 && obj.velocityY > 0) ||
                        (res.axis.y > 0 && obj.velocityY < 0))
                        obj.velocityY = this.velocityY;
                }
                else
                {
                    // Otherwise, split the difference and just stop.
                    if ((res.axis.x < 0 && obj.velocityX > 0) ||
                        (res.axis.x > 0 && obj.velocityX < 0))
                        obj.velocityX = 0;
                    if ((res.axis.y < 0 && obj.velocityY > 0) ||
                        (res.axis.y > 0 && obj.velocityY < 0))
                        obj.velocityY = 0;   

                    this.bumped = true;
                }
                
                // Set wall / ground flags
                if (res.axis.y == -1)
                    obj.onGround = true;
                if (res.axis.x != 0)
                    obj.onWall = res.axis.x;
                
                return true;
            }
            return false;
        } 

        private function fireCollideObj( obj:PlatformerMover, other:PlatformerMover, res:PlatformerResolutionVector )
        {
          obj.onCollideObject(obj, other, res);
        }

      private static var _boundsCache:Rectangle = new Rectangle();
      
      public function get bounds():Rectangle
      {
        _boundsCache.setTo(
          positionX - solidSizeX * 0.5,
          positionY - solidSizeY * 0.5,
          solidSizeX,
          solidSizeY
        );

        return _boundsCache;
      }

      /**
      * Gets the top left corner point of the object in world space (X)
      */
      public function get topLeftX():Number
      {
        return positionX - solidSizeX * 0.5;
      }

      /**
      * Gets the top left corner point of the object in world space (Y)
      */
      public function get topLeftY():Number
      {
        return positionY - solidSizeY * 0.5;
      }
      
	private static function rectsOverlap(rectA:Rectangle, rectB:Rectangle):Boolean
	{
	    return ((rectA.x <= rectB.right) &&
	            (rectB.x <= rectA.right) &&
	            (rectA.y <= rectB.bottom) &&
	            (rectB.y <= rectA.bottom));
	}
      
   }
}