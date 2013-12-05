package
{
    import loom.Application;

    import loom2d.Loom2D;    

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    
    import loom2d.animation.Transitions;
    
    import loom2d.math.Point;

    import loom2d.tmx.TMXDocument;
    import loom2d.tmx.TMXObjectGroup;
    import loom2d.tmx.TMXObject;
    import loom2d.tmx.TMXMapSprite;


	/**
	 * Create and render a TMX tilemap created by Tiled.
	 */
	 
    public class TMXDemo extends Application
    {
        public var map:TMXMapSprite;
        public var last:Number = 0;
        public var delta:Number = 0;
        
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Load our tmx file and listen for when parts of it are parsed.
            var tmx:TMXDocument = new TMXDocument("assets/example.tmx");
            tmx.onObjectGroupParsed += onObjectGroupParsed;
            tmx.onTMXUpdated += onTMXUpdated;

            // Create a sprite that auto-updates when the map updates.
            map = new TMXMapSprite(tmx);
            map.scale = 0.5;
            map.y = -96;
            stage.addChild(map);

            tmx.load();
            
            stage.addEventListener(TouchEvent.TOUCH, function(e:TouchEvent) { 

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

        private function onTMXUpdated(file:String, tmx:TMXDocument):void
        {
            trace("started parsing tmx: " + file);

            trace("\tversion: " + tmx.version);
            trace("\torientation: " + tmx.orientation);
            trace("\twidth: " + tmx.width);
            trace("\theight: " + tmx.height);
            trace("\ttileWidth: " + tmx.tileWidth);
            trace("\ttileHeight: " + tmx.tileHeight);
            trace("\tbackgroundcolor: " + tmx.backgroundcolor);
        }

        private function onObjectGroupParsed(file:String, group:TMXObjectGroup):void
        {
            trace("parsed object group:", group.name);
            for each (var object:TMXObject in group.objects)
            {
                trace( "\tFound object named", object.name, "at", object.x + ", " + object.y );
            }
        }
        
        private function onTouchBegan(id:Number, x:Number, y:Number)
        {
            Loom2D.juggler.removeTweens(map);
            last = x;
        }

        private function onTouchMoved(id:Number, x:Number, y:Number)
        {
            delta = x - last;
            map.x += delta;
            last = Math.round(x);
        }

        private function onTouchEnded(id:Number, x:Number, y:Number)
        {
            if(delta > 3 || delta < -3)
            {
                var pos = map.x+(delta*10);
                pos = Math.round(pos);
                Loom2D.juggler.tween(map, 1, {"x": pos, "transition": Transitions.EASE_OUT});
            }
        }
        
    }
}