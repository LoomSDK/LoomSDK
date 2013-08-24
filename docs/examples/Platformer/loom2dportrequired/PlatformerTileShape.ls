package 
{
    import cocos2d.CCDictionary;
    import cocos2d.CCRect;
    import cocos2d.CCSize;
    import cocos2d.CCTMXLayer;
    import loom2d.math.Point;
    import loom.gameframework.TickedComponent;

    /**
     * All the state relating to a tile shape (note we only have one per type of tile).
     */
    public class PlatformerTileShape
    {
        protected var resolutions:Vector.<PlatformerResolutionVector> = [new PlatformerResolutionVector(AXIS_RIGHT), new PlatformerResolutionVector(AXIS_LEFT), new PlatformerResolutionVector(AXIS_DOWN), new PlatformerResolutionVector(AXIS_UP)];

        private static const V_RIGHT:int = 0;
        private static const V_LEFT :int = 1;
        private static const V_DOWN :int = 2;
        private static const V_UP   :int = 3;
        
        private static const AXIS_RIGHT:Point2 = new Point2( 1,  0);
        private static const AXIS_LEFT :Point2 = new Point2(-1,  0);
        private static const AXIS_DOWN :Point2 = new Point2( 0, -1);
        private static const AXIS_UP   :Point2 = new Point2( 0,  1);
        
        public var objectMask:int = 0xff;
		
		public var solidEdgeLeft:Boolean   = false;
		public var solidEdgeRight:Boolean  = false;
		public var solidEdgeTop:Boolean    = false;
		public var solidEdgeBottom:Boolean = false;

        private var _shape:String = "none";
        private var _oneWay:Boolean = false;
		private var _flipX:Boolean = false;
		private var _flipY:Boolean = false;
		
		private var buildResolutions:Function = getResolutionsNone;

        public function PlatformerTileShape(shape:String, xFlip:Boolean, yFlip:Boolean, onlyOneWay:Boolean)
        {
            // HACK TO WORK AROUND PROBLEM WITH POINT2
            AXIS_RIGHT.x = 1;
            AXIS_RIGHT.y = 0;
            AXIS_LEFT.x = -1;
            AXIS_LEFT.y = 0;
            AXIS_DOWN.x = 0;
            AXIS_DOWN.y = -1;
            AXIS_UP.x = 0;
            AXIS_UP.y = 1;
            // END HACK

            _shape  = shape;
            _flipX  = xFlip;
            _flipY  = yFlip;
            _oneWay = onlyOneWay;

            Console.print("PlatformerTileShape - '" + _shape + "': " + _flipX + ", " + _flipY + " (" + _oneWay + ")");

            refreshShapeCache();
        }
        
        public function contactVsObj( obj:PlatformerMover, mapLayer:CCTMXLayer, tilex:int, tiley:int ): Boolean
        {
            // If there is no valid resolution vector, then we're not colliding.
            
            // TODO: This could possibly be optimized with simpler checks?  
            return (resolveVsObj(obj, mapLayer, tilex, tiley, false) != null)
        }
		
        public function tileBoundsForCoord( mapLayer:CCTMXLayer, tilex:int, tiley:int):CCRect {
          var tileSize = mapLayer.getMapTileSize();
          var mapSize = mapLayer.getLayerSize();

          var retVal:CCRect = new CCRect();
          retVal.setRect(   tilex * tileSize.width,
                            ((mapSize.height - tiley - 1) * tileSize.height),
                            tileSize.width,
                            tileSize.height );

//          Algebra to solve for pixelY
//          tileY = ((mapH * tileH) - pixelY) / tileH;
//          tileY * tileH = ((mapH * tileH) - pixelY);
//          mapH * tileH - tileY * tileH = pixelY;
//          (mapH - tileY) * tileH = pixelY;

          return retVal;
        }

        public function getResolutions( obj:PlatformerMover, mapLayer:CCTMXLayer, tilex:int, tiley:int, doCull:Boolean = true ):Vector.<PlatformerResolutionVector>
        {
            var tileSize:CCSize = mapLayer.getMapTileSize();
            var tileBounds:CCRect = tileBoundsForCoord(mapLayer, tilex, tiley);

            if (shape == "none")
                return null;
            
            if (!tileBounds.intersectsRect(obj.dest)) // rectsOverlap(tileBounds, obj.dest)) // 
            {
                return null;
            }

            // Find how far in each axis we'd have to displace the object to get it out of collision.
            switch (shape)
            {
                case "full":
                    getResolutionsFull(obj, tileBounds);
                    break;
                    //*
                case "45":
                    getResolutions45(obj, tileBounds);
                    break;
                case "22a":
                    getResolutions22a(obj, tileBounds);
                    break;
                case "22b":
                    getResolutions22b(obj, tileBounds);
                    break;
                case "67a":
                    getResolutions67a(obj, tileBounds);
                    break;
                case "67b":
                    getResolutions67b(obj, tileBounds);
                    break;
                    /*
                case "round":
                    // TODO:
                    getResolutionsRound(obj, tileBounds);
                    break;
                case "concave":
                    getResolutionsConcave(obj, tileBounds);
                    break;
                    //*/
                case "halfh":
                    getResolutionsHalfH(obj, tileBounds);
                    break;
                case "halfv":
                    getResolutionsHalfV(obj, tileBounds);
                    break;
                case "quarter":
                    getResolutionsQuarter(obj, tileBounds);
                    break;
                case "none":
                default:
                    getResolutionsNone(obj, tileBounds);
                    break;
            }

            if (doCull)
                cullResolutions(obj, mapLayer, tilex, tiley, tileBounds);


            // Disqualify vectors based on whether or not we're one-way
            if (_oneWay) 
            {
                resolutions[V_RIGHT].enabled = false;
                resolutions[V_LEFT].enabled = false;
                resolutions[V_DOWN].enabled = false;
                
                if (obj.bounds.getMinY() < tileBounds.getMaxY() && _shape == "full")
                    resolutions[V_UP].enabled = false;
            }                

            return resolutions;            
        }


        public function resolveVsObj( obj:PlatformerMover, mapLayer:CCTMXLayer, tilex:int, tiley:int, doCull:Boolean = true ):PlatformerResolutionVector
        {
            getResolutions(obj, mapLayer, tilex, tiley, doCull);
            
            // Find the minimum collision resolution vector
            var minRes:int = -1;
            for (var cnt:int = 0; cnt < 4; cnt++) {
                if (resolutions[cnt].enabled) {
                    if ((minRes == -1) || 
                        (resolutions[cnt].distance < resolutions[minRes].distance))
                        minRes = cnt;
                }
            }

            var _minRes:int = minRes;

			// If we have a valid resolution vector, then return it.
            if (minRes != -1)
            {
                if (resolutions[minRes].distance > 0)
                {
                    return resolutions[minRes];
                }
            }
            
            // Otherwise, return that we have no collision vector available
            return null;            
        }
		
		private function cullResolutions(obj:PlatformerMover, mapLayer:CCTMXLayer, tilex:int, tiley:int, tileBounds:CCRect):void
		{ 
			// Disqualify resolution vectors based on the objects' velocity
            if ((obj.velocityX > 0) && (resolutions[V_RIGHT].distance != 0))
                resolutions[V_RIGHT].enabled = false;
            
            if ((obj.velocityX < 0) && (resolutions[V_LEFT].distance != 0))
                resolutions[V_LEFT].enabled = false;

            if ((obj.velocityY < 0) && (resolutions[V_DOWN].distance != 0))
                resolutions[V_DOWN].enabled = false;
            
            // TODO: May need to check for angled tiles here once implemented
            if ((obj.velocityY > 0) && (resolutions[V_UP].distance != 0))
                resolutions[V_UP].enabled = false;

            // Disqualify resolution for directions that have solid edges that are butted up against other solid edges.
            // This helps to mitigate false catches on edges
            var otherShape:PlatformerTileShape;

            if ((solidEdgeRight) && (resolutions[V_RIGHT].enabled))
            {
                otherShape = PlatformerMoverManager.getTileShape(mapLayer, tilex + 1, tiley);
                if (otherShape != null)
                    if (otherShape.solidEdgeLeft)
                        resolutions[V_RIGHT].enabled = false;
            }
            if ((solidEdgeLeft) && (resolutions[V_LEFT].enabled))
            {
                otherShape = PlatformerMoverManager.getTileShape(mapLayer, tilex - 1, tiley);
                if (otherShape != null)
                    if (otherShape.solidEdgeRight)
                        resolutions[V_LEFT].enabled = false;
            }
            if ((solidEdgeBottom) && (resolutions[V_DOWN].enabled))
            {
                otherShape = PlatformerMoverManager.getTileShape(mapLayer, tilex, tiley + 1);
                if (otherShape != null)
                    if (otherShape.solidEdgeTop)
                        resolutions[V_DOWN].enabled = false;
            }
            if ((solidEdgeTop) && (resolutions[V_UP].enabled))
            {
                otherShape = PlatformerMoverManager.getTileShape(mapLayer, tilex, tiley - 1);
                if (otherShape != null)
                    if (otherShape.solidEdgeBottom)
                        resolutions[V_UP].enabled = false;
            }

            // Cull resolutions that are too large to be reasonable.
            for (var cnt:int = 0; cnt < 4; cnt++)
            {
                // Assume that objects can't move faster than their max velocity.
                if ((resolutions[cnt].distance > obj.velocityMaxY) &&
                    (resolutions[cnt].distance > obj.velocityMaxX))
                {
                    resolutions[cnt].enabled = false;
                }
            }
		}
		
		private function getResolutionsNone( obj:PlatformerMover, tileBounds:CCRect ):void
		{
            resolutions[V_RIGHT].distance = 0;
            resolutions[V_LEFT].distance  = 0;
            resolutions[V_DOWN].distance  = 0;
            resolutions[V_UP].distance    = 0;
			
			resolutions[V_RIGHT].enabled  = false;
			resolutions[V_LEFT].enabled   = false;
			resolutions[V_DOWN].enabled   = false;
			resolutions[V_UP].enabled     = false;
		}
		
		private function getResolutionsFull( obj:PlatformerMover, tileBounds:CCRect ):void
		{
            resolutions[V_RIGHT].distance = tileBounds.getMaxX() -    obj.dest.getMinX();
            resolutions[V_LEFT].distance  =   obj.dest.getMaxX() -  tileBounds.getMinX();
            resolutions[V_DOWN].distance  = -(tileBounds.getMinY() -    obj.dest.getMaxY());
            resolutions[V_UP].distance    =   -(obj.dest.getMinY() -  tileBounds.getMaxY());

			resolutions[V_RIGHT].enabled  = true;
			resolutions[V_LEFT].enabled   = true;
			resolutions[V_DOWN].enabled   = true;
			resolutions[V_UP].enabled     = true;
		}
        
        private function getResolutionsPartial( obj:PlatformerMover, tileBounds:CCRect, sizeX:Number, sizeY:Number):void
        {
            if (!flipX)
                tileBounds.originX += (1 - sizeX) * tileBounds.width;
            if (flipY)
                tileBounds.originY += (1 - sizeY) * tileBounds.height;
            
            tileBounds.height *= sizeY;
            tileBounds.width *= sizeX;
            
            if ( tileBounds.intersectsRect(obj.dest))
                getResolutionsFull(obj, tileBounds);
            else
                getResolutionsNone(obj, tileBounds);
        }
        
        private function getResolutionsQuarter( obj:PlatformerMover, tileBounds:CCRect ):void
        {
            getResolutionsPartial( obj, tileBounds, 0.5, 0.5);
        }

        private function getResolutionsHalfH( obj:PlatformerMover, tileBounds:CCRect ):void
        {
            getResolutionsPartial( obj, tileBounds, 1, 0.5);
        }
        private function getResolutionsHalfV( obj:PlatformerMover, tileBounds:CCRect ):void
        {
            getResolutionsPartial( obj, tileBounds, 0.5, 1);
        }
        
        private function getResolutionsConcave( obj:PlatformerMover, tileBounds:CCRect):void
        {
            // TODO: Implement
            getResolutionsNone( obj, tileBounds );
        }
		
		private function getResolutionsRound( obj:PlatformerMover, tileBounds:CCRect):void
		{
            // TODO: Implement
            getResolutionsNone( obj, tileBounds );
		}

		private function getResolutionSloped( obj:PlatformerMover, tileBounds:CCRect, slope:Number, invSlope:Number, yOffset:Number):void
		{
            getResolutionsFull( obj, tileBounds );

            var overlapY:int = obj.bounds.getMinY() - tileBounds.getMinY();
            var overlapX:int = tileBounds.getMaxX() - obj.bounds.getMaxY();

            // If the bottom edge of the object is above the bottom edge of the tile
            if (overlapY > 0)
            {
                // If the right edge of the object is to the left of the right edge of the tile
                if (overlapX > 0) 
                {
                    // Then we need to do some slope calculations
                    
                }
            }



            // TODO: Implement
            getResolutionsNone( obj, tileBounds );
		}
		
        //        /|
        //      /  |
        //    /    |
        //  /______|
		private function getResolutions45( obj:PlatformerMover, tileBounds:CCRect ):void
		{
            // TODO: Implement
			getResolutionSloped( obj, tileBounds, 1, 1, 0 );
		}

        //      _-`|
        //   _-`___|
		private function getResolutions22a( obj:PlatformerMover, tileBounds:CCRect ):void
		{
            // TODO: Implement
			getResolutionSloped( obj, tileBounds, 0.5, 2, 0 );
		}

        //      _-`|
        //   _-`   |
        //  |      |
        //  |______|
		private function getResolutions22b( obj:PlatformerMover, tileBounds:CCRect ):void
		{
            // TODO: Implement
			getResolutionSloped( obj, tileBounds, 0.5, 2, (tileBounds.getMaxY() - tileBounds.getMinY()) * 0.5 );
		}

        //       /|
        //      / |
        //     /__|
		private function getResolutions67a( obj:PlatformerMover, tileBounds:CCRect ):void
		{
            // TODO: Implement
			getResolutionSloped( obj, tileBounds, 2, 0.5, -(tileBounds.getMaxY() - tileBounds.getMinY()) );
		}

        //      ___
        //    /    |
        //   /     |
        //  /______|
		private function getResolutions67b( obj:PlatformerMover, tileBounds:CCRect ):void
		{
            // TODO: Implement
			getResolutionSloped( obj, tileBounds, 2, 0.5, 0 );
		}
		
		public function set shape(value:String):void {
			_shape = value.toLowerCase();
			refreshShapeCache();
		}
		public function get shape():String {
			return _shape;
		}
		
		public function set oneWay(value:Boolean):void {
			_oneWay = value;
			refreshShapeCache();
		}
		public function get oneWay():Boolean {
			return _oneWay;
		}
		
		public function set flipX(value:Boolean):void {
			_flipX = value;
			refreshShapeCache();
		}
		public function get flipX():Boolean {
			return _flipX;
		}

		public function set flipY(value:Boolean):void {
			_flipY = value;
			refreshShapeCache();
		}		
		public function get flipY():Boolean {
			return _flipY;
		}

        public function rectsOverlap(rectA:CCRect, rectB:CCRect):Boolean {
            return ((rectA.getMinX() < rectB.getMaxX()) &&
                    (rectB.getMinX() < rectA.getMaxX()) &&
                    (rectA.getMinY() < rectB.getMaxY()) &&
                    (rectB.getMinY() < rectA.getMaxY()));
        }

		
		private function refreshShapeCache():void 
		{
            // Update our edge solidity for non-simple edges
			switch (_shape)
			{
				case "full":
					solidEdgeLeft   = true;
					solidEdgeRight  = true;
					solidEdgeTop    = true;
					solidEdgeBottom = true;
					break;
				case "halfh":
					solidEdgeLeft   = false;
					solidEdgeRight  = false;
					solidEdgeTop    = flipY;
					solidEdgeBottom = !solidEdgeTop;
					break;
				case "halfv":
					solidEdgeLeft   = flipX;
					solidEdgeRight  = !solidEdgeLeft;
					solidEdgeTop    = false;
					solidEdgeBottom = false;
					break;
				case "quarter":
                    solidEdgeLeft   = false;
                    solidEdgeRight  = false;
                    solidEdgeTop    = false;
                    solidEdgeBottom = false;
                    break;
				case "45":
                case "round":
                case "concave":
                    solidEdgeLeft   = flipX;
                    solidEdgeRight  = !solidEdgeLeft;
                    solidEdgeTop    = flipY;
                    solidEdgeBottom = !solidEdgeTop;
                    break;
				case "22a":
				case "22b":
				case "67a":
				case "67b":
                // TODO:
					solidEdgeLeft   = flipX;
					solidEdgeRight  = !solidEdgeLeft;
					solidEdgeTop    = flipY;
					solidEdgeBottom = !solidEdgeTop;
					break;
				case "none":
				default:
					solidEdgeLeft   = false;
					solidEdgeRight  = false;
					solidEdgeTop    = false;
					solidEdgeBottom = false;
					break;
			}
			
			if (_oneWay) {
				solidEdgeLeft   = false;
				solidEdgeRight  = false;
				solidEdgeBottom = false;
			}
		}		
    }
}