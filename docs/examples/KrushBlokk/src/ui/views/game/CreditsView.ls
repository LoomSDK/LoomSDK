package ui.views.game
{
    import loom.platform.Mobile;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.Image;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.math.Point;
    import loom2d.textures.Texture;
    import ui.views.View;
    import ui.views.ViewCallback;

    /**
     * View displaying the credits and not much else.
     */
    class CreditsView extends View
    {	
        [Bind] public var credits:Image;
        
        // Delta time for framerate independent units
        private static var dt = 1/60;
        
        // Default automatic scrolling speed
        private var scrollSpeed = 7 * dt;
        
        // Current scrolling speed
        private var speed:Number;
        private var h:Number;
        
        public function init()
        {
            super.init();
            credits = new Image(Texture.fromAsset("assets/credits.png"));
            addChild(credits);
        }
        
        public function resize(w:Number, h:Number)
        {
            super.resize(w, h);
            this.h = h;
            // Scales credits to fit width
            credits.scale = w/credits.texture.width;
            credits.y = h;
        }
        
        public function enter(owner:DisplayObjectContainer)
        {
            super.enter(owner);
            stage.addEventListener(TouchEvent.TOUCH, touch);
            speed = 0;
            credits.y = h;
            Mobile.allowScreenSleep(false);
        }
        
        override public function tick()
        {
            super.tick();
            credits.y -= speed;
            if (credits.y < -credits.height) {
                onBack();
            }
            speed += (scrollSpeed-speed)*0.2;
        }
        
        private function touch(e:TouchEvent)
        {
            var t = e.getTouch(stage);
            speed -= (t.getLocation(stage).y-t.getPreviousLocation(stage).y)*4*dt;
        }
        
        public function exit()
        {
            stage.removeEventListener(TouchEvent.TOUCH, touch);
            super.exit();
            Mobile.allowScreenSleep(true);
        }
    }
}