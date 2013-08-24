package loom2d.ui 
{
    import loom2d.display.DisplayObject;
    import loom2d.events.Event;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    
    delegate ButtonClickCallback():void;
    
    /**
     * Simple button class that can use Atlas to resolve texture references.
     */
    public class SimpleButton extends TextureAtlasSprite
    {
        /**
         * Fired when user clicks on the button.
         */
        public var onClick:ButtonClickCallback;
        
        /**
         * Like textureName, but set when the button is not pressed.
         */
        public var upImage:String;

        /**
         * Like textureName, but set when the button is depressed.
         */
        public var downImage:String;
        
        public function SimpleButton() 
        {
            touchable = true;
            super();
            addEventListener(TouchEvent.TOUCH, onTouchDown);
        }
        
        protected function onTouchDown(e:TouchEvent, d:Object):void
        {
            if(e.getTouch(this, TouchPhase.BEGAN) != null)
            {
                textureName = downImage;
                e.stopPropagation();
                return;
            }

            if(e.getTouch(this, TouchPhase.ENDED) != null)
            {
                textureName = upImage;
                e.stopPropagation();
                onClick();
                return;
            }
        }

        protected function validate() 
        {
            
            if(textureName == null)
                textureName = upImage;

            super();
        }
        
    }
    
}