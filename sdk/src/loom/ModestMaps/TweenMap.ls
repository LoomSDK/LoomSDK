/**
 * vim:et sts=4 sw=4 cindent:
 * @ignore
 *
 * @author tom
 *
 * loom.modestmaps.TweenMap adds smooth animated panning and zooming to the basic Map class
 *
 */
package loom.modestmaps
{
    import loom.modestmaps.core.Coordinate;
    import loom.modestmaps.core.MapExtent;
    import loom.modestmaps.core.TweenTile;
    import loom.modestmaps.geo.Location;
    import loom.modestmaps.core.TileGrid;
    import loom.modestmaps.mapproviders.IMapProvider;
    import loom2d.display.Stage;
    import loom2d.events.Event;
    import loom2d.math.Matrix;
    import loom2d.math.Point;
    
    import loom2d.Loom2D;
    import loom2d.animation.Tween;
    import loom2d.animation.Transitions;
    import loom2d.animation.DelayedCall;
    
    import loom2d.events.ScrollWheelEvent;    


    public class TweenMap extends Map
    {

        /** easing function used for panLeft, panRight, panUp, panDown */
        public var panEase:Function = Transitions.getTransition(Transitions.EASE_OUT);
        /** time to pan using panLeft, panRight, panUp, panDown */
        public var panDuration:Number = 0.5;

        /** easing function used for zoomIn, zoomOut */
        public var zoomEase:Function = Transitions.getTransition(Transitions.EASE_OUT);
        /** time to zoom using zoomIn, zoomOut */
        public var zoomDuration:Number = 0.2;

        /** time to pan and zoom using, uh, panAndZoom */
        public var panAndZoomDuration:Number = 0.3;
        
        protected var mouseWheelingIn:Boolean = false;
        protected var mouseWheelingOut:Boolean = false;

        /*
        * Initialize the map: set properties, add a tile grid, draw it.
        * Default extent covers the entire globe, (+/-85, +/-180).
        *
        * @param    Width of map, in pixels.
        * @param    Height of map, in pixels.
        * @param    Whether the map can be dragged or not.
        * @param    Desired map provider, e.g. Blue Marble.
        *
        * @see loom.modestmaps.core.TileGrid
        */
        public function TweenMap(width:Number, height:Number, draggable:Boolean, provider:IMapProvider, mapStage:Stage, ... rest)
        {
            super(width, height, draggable, provider, mapStage, rest);
            grid.setTileCreator(CreateTweenTile);
        }

        /* Custom Tile creator factor function for this map type */
        protected function CreateTweenTile():TweenTile
        {
            return new TweenTile(0, 0, 0);
        }

       /** Pan by px and py, in panDuration (used by panLeft, panRight, panUp and panDown) */
        override public function panBy(px:Number, py:Number):void
        {
            if (!grid.panning && !grid.zooming) {
                grid.prepareForPanning();
                Loom2D.juggler.tween(grid, panDuration, {"ty": grid.ty + py,
                                                         "tx": grid.tx + px,
                                                         "transitionFunc": panEase,
                                                         "onComplete": grid.donePanning});
            }
        }      
                    
        protected var enforceToRestore:Boolean = false;
        
        public function tweenToMatrix(m:Matrix, duration:Number):void
        {
            grid.prepareForZooming();
            grid.prepareForPanning();
            enforceToRestore = TileGrid.EnforceBoundsEnabled;
            TileGrid.EnforceBoundsEnabled = false;

            grid.enforceBoundsOnMatrix(m);
            Loom2D.juggler.tween(grid, duration, { "a": m.a, 
                                                    "b": m.b, 
                                                    "c": m.c, 
                                                    "d": m.d, 
                                                    "tx": m.tx, 
                                                    "ty": m.ty, 
                                                    "onComplete": panAndZoomComplete });                
        }

        /** call grid.donePanning() and grid.doneZooming(), used by tweenExtent, 
         *  panAndZoomBy and zoomByAbout as a TweenLite onComplete function */
        protected function panAndZoomComplete():void
        {
            TileGrid.EnforceBoundsEnabled = enforceToRestore;
            
            grid.donePanning();
            grid.doneZooming();
        }       
        
        /** zoom in or out by sc, moving the given location to the requested target (or map center, if omitted) */        
        override public function panAndZoomBy(sc:Number, location:Location, targetPoint:Point, duration:Number=-1):void
        {
            if (duration < 0) duration = panAndZoomDuration;
            
            calcLocationPoint(location);
            
            var constrainedDelta:Number = Math.log(sc) / Math.LN2;

            if (grid.zoomLevel + constrainedDelta < grid.minZoom) {
                constrainedDelta = grid.minZoom - grid.zoomLevel;               
            }
            else if (grid.zoomLevel + constrainedDelta > grid.maxZoom) {
                constrainedDelta = grid.maxZoom - grid.zoomLevel; 
            }
            
            // round the zoom delta up or down so that we end up at a power of 2
            var preciseZoomDelta:Number = constrainedDelta + (Math.round(grid.zoomLevel+constrainedDelta) - (grid.zoomLevel+constrainedDelta));
            
            sc = Math.pow(2, preciseZoomDelta);
            
            var m:Matrix = grid.getMatrix();
            
            m.translate(-grid.CoordinatePoint.x, -grid.CoordinatePoint.y);
            m.scale(sc, sc);
            m.translate(targetPoint.x, targetPoint.y);
            
            tweenToMatrix(m, duration);
        }

        /** zoom in or out by zoomDelta, keeping the requested point in the same place */        
        override public function zoomByAbout(zoomDelta:Number, targetPoint:Point, duration:Number=-1):void
        {
            if (duration < 0) duration = panAndZoomDuration;

            var constrainedDelta:Number = zoomDelta;

            if (grid.zoomLevel + constrainedDelta < grid.minZoom) {
                constrainedDelta = grid.minZoom - grid.zoomLevel;               
            }
            else if (grid.zoomLevel + constrainedDelta > grid.maxZoom) {
                constrainedDelta = grid.maxZoom - grid.zoomLevel; 
            }
            
            // round the zoom delta up or down so that we end up at a power of 2
            var preciseZoomDelta:Number = constrainedDelta + (Math.round(grid.zoomLevel+constrainedDelta) - (grid.zoomLevel+constrainedDelta));

            var sc:Number = Math.pow(2, preciseZoomDelta);
            
            var m:Matrix = grid.getMatrix();
            
            m.translate(-targetPoint.x, -targetPoint.y);
            m.scale(sc, sc);
            m.translate(targetPoint.x, targetPoint.y);
            
            tweenToMatrix(m, duration); 
        }
        
        /** EXPERIMENTAL! */
        public function tweenExtent(extent:MapExtent, duration:Number=-1):void
        {
            if (duration < 0) duration = panAndZoomDuration;

            var coord:Coordinate = locationsCoordinate([extent.northWest, extent.southEast]);

            var sc:Number = Math.pow(2, coord.zoom-grid.zoomLevel);
            
            grid.calcCoordinatePoint(coord, grid);
            
            var m:Matrix = grid.getMatrix();
            
            m.translate(-grid.CoordinatePoint.x, -grid.CoordinatePoint.y);
            m.scale(sc, sc);
            m.translate(mapWidth/2, mapHeight/2);
            
            tweenToMatrix(m, duration); 
        }

       /**
         * Put the given location in the middle of the map, animated in panDuration using panEase.
         * 
         * Use setCenter or setCenterZoom for big jumps, set forceAnimate to true
         * if you really want to animate to a location that's currently off screen.
         * But no promises! 
         * 
         * @see loom.modestmaps.TweenMap#panDuration
         * @see loom.modestmaps.TweenMap#panEase
         * @see loom.modestmaps.TweenMap#tweenTo
         */
        public function panTo(location:Location, forceAnimate:Boolean=false):void
        {
            calcLocationPoint(location, grid);
            var px = grid.CoordinatePoint.x;
            var py = grid.CoordinatePoint.y;

            if (forceAnimate || (px >= 0 && px <= mapWidth && py >= 0 && py <= mapHeight))
            {
                var panX:Number = (mapWidth / 2) - px;
                var panY:Number = (mapHeight / 2) - py;
                Loom2D.juggler.tween(grid, panDuration, {"ty": grid.ty + panY,
                                                         "tx": grid.tx + panX,
                                                         "transitionFunc": panEase,
                                                         "onStart": grid.prepareForPanning,
                                                         "onComplete": grid.donePanning});
                    
            }
            else
            {
                setCenter(location);
            }
        }

       /**
         * Animate to put the given location in the middle of the map.
         * Use setCenter or setCenterZoom for big jumps, or panTo for pre-defined animation.
         * 
         * @see loom.modestmaps.Map#panTo
         */
        public function tweenTo(location:Location, duration:Number, easing:Function=null):void
        {
            calcLocationPoint(location, grid);
            var panX:Number = (mapWidth / 2) - grid.CoordinatePoint.x;
            var panY:Number = (mapHeight / 2) - grid.CoordinatePoint.y;
            Loom2D.juggler.tween(grid, duration, { "ty": grid.ty + panY,
                                                   "tx": grid.tx + panX,
                                                   "transitionFunc": easing,
                                                   "onStart": grid.prepareForPanning,
                                                   "onComplete": grid.donePanning });
        }
        
        // keeping it DRY, as they say    
        // dir should be 1, for in, or -1, for out
        override protected function zoomBy(dir:int):void
        {
            if (!grid.panning)
            {
                var target:Number = (dir < 0) ? Math.floor(grid.zoomLevel + dir) : Math.ceil(grid.zoomLevel + dir);
                target = Math.max(grid.minZoom, Math.min(grid.maxZoom, target));

                Loom2D.juggler.tween(grid, zoomDuration, { "zoomLevel": target,
                                                           "onStart": grid.prepareForZooming,
                                                           "onComplete": grid.doneZooming,
                                                           "transitionFunc": zoomEase });
            }
        }

        private var _delayedMouseDone:DelayedCall = null;

        /** 
         * Zooms in or out of mouse-wheeled location, rounded off to nearest whole zoom level when zooming ends.
         *
         * @see http://blog.pixelbreaker.com/flash/swfmacmousewheel/ for Mac mouse wheel support  
         */
         override public function onMouseWheel(event:ScrollWheelEvent):void
         {          
            if (!__draggable || grid.panning) return;

            Loom2D.juggler.removeTweens(grid);
            if(_delayedMouseDone != null)
            {
                Loom2D.juggler.remove(_delayedMouseDone);
            }

            var sc:Number = 0;
            if (event.delta < 0) {
                if (grid.zoomLevel > grid.minZoom) {
                    mouseWheelingOut = true;
                    mouseWheelingIn = false;
                    sc = Math.max(0.5, 1.0+event.delta/20.0);
                }
            }
            else if (event.delta > 0) {
                if (grid.zoomLevel < grid.maxZoom) {
                    mouseWheelingIn = true;
                    mouseWheelingOut = false;                   
                    sc = Math.min(2.0, 1.0+event.delta/20.0);               
                }
            }

            if (sc) {
                //NOTE_TEC: Loom ScrollWheelEvent doesn't provide a mouseXY, so we'll just zoom by the screen center
                //var p:Point = grid.globalToLocal(new Point(event.stageX, event.stageY));            
                var p:Point = grid.globalToLocal(new Point(stage.stageWidth / 2, stage.stageHeight / 2));            
                var m:Matrix = grid.getMatrix();
                m.translate(-p.x, -p.y);
                m.scale(sc, sc);
                m.translate(p.x, p.y);
                grid.setMatrix(m);              
            }

            _delayedMouseDone = Loom2D.juggler.delayCall(doneMouseWheeling, 0.1);
        }

        protected function doneMouseWheeling():void
        {
            //NOTE_TEC: Loom ScrollWheelEvent doesn't provide a mouseXY, so we'll just zoom by the screen center
            //var p:Point = grid.globalToLocal(new Point(stage.mouseX, stage.mouseY));
            var p:Point = grid.globalToLocal(new Point(stage.stageWidth / 2, stage.stageHeight / 2));
            if (mouseWheelingIn) { 
                zoomByAbout(Math.ceil(grid.zoomLevel) - grid.zoomLevel, p, 0.15); // round off to whole value up
            }
            else if (mouseWheelingOut) { 
            zoomByAbout(Math.floor(grid.zoomLevel) - grid.zoomLevel, p, 0.15); // round off to whole value down
            }
            else {
                zoomByAbout(Math.round(grid.zoomLevel) - grid.zoomLevel, p, 0.15); // round off to whole value down
            }
            mouseWheelingOut = false;
            mouseWheelingIn = false;
            _delayedMouseDone = null;
        }
    }
}