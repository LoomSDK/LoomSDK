package ui.views.game
{
    import feathers.controls.Label;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import system.platform.Platform;
    import ui.views.ConfigView;
    import ui.views.ViewCallback;
    
    /**
     * View responsible for displaying an ad with "break time" functionality,
     * preventing the ads being too frequent.
     */
    public class AdView extends ConfigView
    {
        public var onContinue:ViewCallback;
        
        /** Ad break time in milliseconds */
        public var adBreakTime = 3*60*1000;
        
        private var lastTime = -adBreakTime;
        
        //private var ad:InterstitialAd;
        /** Ad placeholder */
        private var adLabel:Label;
        
        override public function init()
        {
            super.init();
            adLabel = new Label();
            // Label style, see Theme for more
            adLabel.nameList.add("header");
            adLabel.text = "ChEck OUT LoomSDK.com";
            adLabel.validate();
            adLabel.visible = false;
            addChild(adLabel);
        }
        
        /**
         * Position the ad in the center of the screen
         */
        override public function resize(w:Number, h:Number)
        {
            super.resize(w, h);
            adLabel.setSize(w, 20);
            adLabel.y = (h-adLabel.height)/2;
        }
        
        /**
         * Show the ad if one wasn't already shown in the last `adbreaktime` milliseconds.
         */
        override public function enter(owner:DisplayObjectContainer)
        {
            super.enter(owner);
            var time = Platform.getTime();
            if (time-lastTime >= adBreakTime) {
                lastTime = time;
                showAd();
            } else {
                onContinue();
            }
        }
        
        /**
         * Show the ad and continue on touch
         */
        private function showAd()
        {
            adLabel.visible = true;
            stage.addEventListener(TouchEvent.TOUCH, touch);
        }
        
        private function touch(e:TouchEvent)
        {
            if (!e.getTouch(stage, TouchPhase.BEGAN)) return;
            hideAd();
        }
        
        private function hideAd()
        {
            adLabel.visible = false;
            stage.removeEventListener(TouchEvent.TOUCH, touch);
            onContinue();
        }
        
        override public function exit()
        {
            super.exit();
        }
        
    }
}