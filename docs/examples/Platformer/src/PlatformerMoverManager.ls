package
{
   import loom2d.tmx.TMXLayer;
   import loom2d.math.Point;
   import loom.gameframework.TimeManager;

   /**
    * Manager for tracking and resolving collisions.
    */
   public class PlatformerMoverManager
   {
      [Inject]
      public var timeManager:TimeManager;

      public static var tileShapes:Vector.<PlatformerTileShape> = new Vector.<PlatformerTileShape>();
      public static var emptyShape:PlatformerTileShape;
      public static var _collisionLayers:Vector.<TMXLayer> = new Vector.<TMXLayer>();
      public function get collisionLayers():Vector.<TMXLayer> {
        return _collisionLayers;
      }

      protected var _platformerObjectList:Vector.<PlatformerMover> = new Vector.<PlatformerMover>();
      public function get platformerObjectList():Vector.<PlatformerMover> {
        return _platformerObjectList;
      }

      public function PlatformerMoverManager()
      {
        emptyShape = new PlatformerTileShape("none", false, false, false);
      }

      public function setTileCollisions( formatString:String ):void
      {
        // Clear out the old shapes
        tileShapes = new Vector.<PlatformerTileShape>();

        var formatLen:int = formatString.length;

        var full:PlatformerTileShape = new PlatformerTileShape( 
            /* shape */ "full", false, false, false);
        var oneWay:PlatformerTileShape = new PlatformerTileShape( 
            /* shape */ "full", false, false, true);

        for (var cnt:int = 0; cnt < formatLen; cnt++)
        {
          var t:String = formatString.charAt(cnt);

          switch (t)
          {
            case ".":
              tileShapes.push(emptyShape);
              break;
            case "X":
            case "@":
              tileShapes.push(full);
              break;
            case "^":
              tileShapes.push(oneWay);
              break;
            case "h":
             tileShapes.push(new PlatformerTileShape( 
                  /* shape */ "halfh",
                  /* flipx */ false,
                  /* flipy */ false, 
                  /* oneway*/ false));
             break;
            case "H":
             tileShapes.push(new PlatformerTileShape( 
                  /* shape */ "halfh",
                  /* flipx */ false,
                  /* flipy */ true, 
                  /* oneway*/ false));
             break;
            case "v":
             tileShapes.push(new PlatformerTileShape( 
                  /* shape */ "halfv",
                  /* flipx */ false,
                  /* flipy */ false, 
                  /* oneway*/ false));
             break;
            case "V":
             tileShapes.push(new PlatformerTileShape( 
                  /* shape */ "halfv",
                  /* flipx */ true,
                  /* flipy */ false, 
                  /* oneway*/ false));
             break;
            case "1":
              tileShapes.push(new PlatformerTileShape( 
                  /* shape */ "quarter",
                  /* flipx */ false,
                  /* flipy */ false, 
                  /* oneway*/ false));
             break;
            case "2":
              tileShapes.push(new PlatformerTileShape( 
                  /* shape */ "quarter",
                  /* flipx */ true,
                  /* flipy */ false, 
                  /* oneway*/ false));
             break;
            case "3":
              tileShapes.push(new PlatformerTileShape( 
                  /* shape */ "quarter",
                  /* flipx */ false,
                  /* flipy */ true, 
                  /* oneway*/ false));
             break;
            case "4":
             tileShapes.push(new PlatformerTileShape( 
                  /* shape */ "quarter",
                  /* flipx */ true,
                  /* flipy */ true, 
                  /* oneway*/ false));
             break;
            default:
              trace("WARNING: Unknown tile map format character '" + t + "'");
              trace("Valid characters are '.', 'X', and '^'");
              if (t != " ")
                tileShapes.push(emptyShape);

              break;
          }
        }
      }

      /**
       * Processes collision for an object vs. the world 
       */
      public function collide( obj:PlatformerMover ):void
      {
          var cnt:int;
          var otherObj:PlatformerMover;
          var mapLayer:TMXLayer;

          // Compare against the tile map layers in the world
          for (cnt = 0; cnt < this._collisionLayers.length; cnt++)
          {
              mapLayer = _collisionLayers[cnt];
              if (mapLayer != null)
              {
                  collideMapVsObj(mapLayer, obj);
              } 
          }
                  
          // Compare it against every other platform object
          for (cnt = 0; cnt < this._platformerObjectList.length; cnt++) 
          {
              otherObj = _platformerObjectList[cnt];
              
              if ((otherObj != null) 
                  && (otherObj != obj))
              {
                  otherObj.collideVsObj( obj );
              }
          }
      }

      public function isColliding( obj:PlatformerMover ):Boolean
      {
        var cnt:int;
        var otherObj:PlatformerMover;
        var mapLayer:TMXLayer;
        
        // Compare against the tile maps in the world
        for (cnt = 0; cnt < _collisionLayers.length; cnt++)
        {
            mapLayer = _collisionLayers[cnt];
            if (mapLayer != null)
            {
                if (contactMapVsObj(mapLayer, obj))
                    return true;
            }
        } 
        
        // Compare it against every other platform object
        for (cnt = 0; cnt < this._platformerObjectList.length; cnt++) 
        {
            otherObj = _platformerObjectList[cnt];
            
            if ((otherObj != null) 
                && (otherObj != obj))
            {
                if (otherObj.contactVsObj(obj))
                    return true;
            }
        }         
        
        return false;
      }

      private var _tilePoint:Point;
      
      public function tileCoordForPosition( mapLayer:TMXLayer, x:Number, y:Number):Point
      {
        _tilePoint.x = Math.floor(x / mapLayer.tileWidth);
        _tilePoint.y = Math.floor(y / mapLayer.tileHeight);
        return _tilePoint;
      }

      public static function getTileShape( mapLayer:TMXLayer, xIndex:int, yIndex:int ):PlatformerTileShape
      {
        if (mapLayer == null)
          return emptyShape;

        var gid:int = mapLayer.getTileGidAt(xIndex, yIndex);

        if (gid > 0 &&
            gid < tileShapes.length)
          return tileShapes[gid-1];
        else
          return emptyShape;
      }
      
      public function contactMapVsObj( mapLayer:TMXLayer, obj:PlatformerMover ):Boolean {
          return collideMapVsObj( mapLayer, obj, false );
      }
      
      private var minCorner:Point;
      private var maxCorner:Point;
      
      public function collideMapVsObj( mapLayer:TMXLayer, obj:PlatformerMover, resolveCollision:Boolean = true ):Boolean {
        var colliding:Boolean = false;

        if (obj.clampMapLeft &&
            obj.dest.x < 0)
        {
          obj.dest.x = 0;
          obj.velocityX = 0;
        }
        if (obj.clampMapRight &&
            obj.dest.right > mapLayer.width * mapLayer.tileWidth)
        {
          obj.dest.x = mapLayer.width * mapLayer.tileWidth - obj.dest.width;
          obj.velocityX = 0;
        }
        if (obj.clampMapBottom &&
            obj.dest.bottom > mapLayer.height * mapLayer.tileHeight)
        {
          obj.dest.y = mapLayer.height * mapLayer.tileHeight - obj.dest.height;
          obj.velocityY = 0;
        }
        if (obj.clampMapTop &&
            obj.dest.y < 0)
        {
          obj.dest.y = 0;
          obj.velocityY = 0;
        }

        // If we fell off the bottom of the map...
        if (obj.dest.y > mapLayer.height * mapLayer.tileHeight)
        {
          Platformer.onFellOffMap(obj);
        }

        minCorner = tileCoordForPosition(mapLayer, obj.dest.x, obj.dest.y);
        
        maxCorner= tileCoordForPosition(mapLayer, obj.dest.right, obj.dest.bottom);
        
        var tileShape:PlatformerTileShape;
        
        var res:PlatformerResolutionVector;

        var reverseX:Boolean = (obj.velocityX < 0);
        
        for (var ycnt:int = minCorner.y; ycnt <= maxCorner.y; ycnt++)
        {
          for (var toggleCnt:int = 0; toggleCnt <= maxCorner.x - minCorner.x; toggleCnt++)
          {
            var xcnt:int;

            if (reverseX)
              xcnt = maxCorner.x - toggleCnt;
            else
              xcnt = minCorner.x + toggleCnt;

            tileShape = getTileShape(mapLayer, xcnt, ycnt);
            
            if (tileShape == null)
              continue;
            
            
            if (tileShape.shape != "none")
            {
              res = null;
              
              if (resolveCollision)
                res = tileShape.resolveVsObj( obj, mapLayer, xcnt, ycnt );
              else
                colliding = colliding || tileShape.contactVsObj( obj, mapLayer, xcnt, ycnt );
              
              // If there is a valid resolution direction...
              if (res != null)
              {
                // Resolve the collisions
                obj.dest.x += res.axis.x * res.distance;
                obj.dest.y += res.axis.y * res.distance;

                // Store the slope
                obj.collisionSlope = res.slope;
                                
                // TODO: Store the overlap
                
                // Kill velocity
                if ((res.axis.x < 0 && obj.velocityX > 0) ||
                  (res.axis.x > 0 && obj.velocityX < 0))
                  obj.velocityX = 0;
                if ((res.axis.y < 0 && obj.velocityY > 0) ||
                  (res.axis.y > 0 && obj.velocityY < 0))
                  obj.velocityY = 0;
                
                // Set wall / ground flags
                if ((res.axis.y == -1) && (obj.velocityY == 0))
                  obj.onGround = true;

                if (res.axis.x != 0)
                  obj.onWall = res.axis.x;
                
                colliding = true;
              }
            }
          }
        }
        
        return colliding;
      }      
   }
}