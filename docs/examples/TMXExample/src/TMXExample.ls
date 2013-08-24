package
{
    import loom.animation.LoomTween;
    import loom.animation.LoomEaseType;
    import loom.LoomTextAsset;

    import loom.Application;    

    import loom2d.display.StageScaleMode;
    
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;

    import loom2d.tmx.TMXTileMap;

    import loom2d.math.Point;

    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;    

    /**
     * Create and render a TMX tilemap created by Tiled.
     */
    public class TMXExample extends Application
    {
        public var last:Number = 0;
        public var map:TMXTileMap;
        public var delta:Number = 0;

        override public function run():void
        {

            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Create a new tilemap from our example TMX file.
            trace("Loading action_map_1.tmx...");
            map = new TMXTileMap();
            map.load("assets/action_map_1.tmx");

            //TODO: LOOM-1502
            // Handle notification when it is reloaded.
            //map.reload += handleReload;

            // adjust map layout to fit screen
            map.y = -96;
            for(var i:int = 0; i < map.layers().length; i++)
            {
                map.layers()[i].getHolder().scale = .5;
                map.addChild(map.layers()[i].getHolder());
            }                         

            // Add it to the layer.
            stage.addChild(map);

            // And trigger the initial parse/load.
            //handleReload();

            stage.addEventListener( TouchEvent.TOUCH, function(e:TouchEvent) { 

                var point:Point;
                var touch = e.getTouch(stage, TouchPhase.BEGAN);

                if (touch)
                {
                    point = touch.getLocation(stage);
                    onTouchBegan(touch.id, point.x, point.y);
                }

                touch = e.getTouch(stage, TouchPhase.MOVED);
                if (touch)
                {
                    point = touch.getLocation(stage);
                    onTouchMoved(touch.id, point.x, point.y);
                }                

                touch = e.getTouch(stage, TouchPhase.ENDED);
                if (touch)
                {
                    point = touch.getLocation(stage);
                    onTouchEnded(touch.id, point.x, point.y);
                }                

            } );            
        }

        protected function onTouchBegan(id:Number, x:Number, y:Number)
        {
            LoomTween.killTweensOf(map);
            last = x;
        }

        protected function onTouchMoved(id:Number, x:Number, y:Number)
        {
            delta = x - last;
            map.x += delta;
            last = Math.round(x);
        }

        protected function onTouchEnded(id:Number, x:Number, y:Number)
        {
            if(delta > 3 || delta < -3)
            {
                var pos = map.x+(delta*10);
                pos = Math.round(pos);
                LoomTween.to(map, 1, {"x": pos, "ease": LoomEaseType.EASE_OUT});
            }
        }

        protected function handleReload():void
        {
            //TODO: LOOM-1502
            /*
            trace("Tilemap was updated!"); 

            // Look up and report on polylines and points, if present.
            var objects = map.objectGroupNamed("Objects")
            if(!objects)
            {
                trace("Group 'Objects' not found.");
                return;
            }

            var open = objects.objectNamed("Open");
            if(open)
            {
                trace("   o Open polygon: ", open.valueForKey("polyline"));
            }
            else
            {
                trace("   o Open polygon not found.");
            }

            var closed = objects.objectNamed("Closed");
            if(closed)
            {
                trace("   o Closed polygon: ", closed.valueForKey("polygon"));
            }
            else
            {
                trace("   o Closed polygon not found.");
            }
            */
        }        
    }
}