package 
{
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.textures.Texture;
    
    /**
     * ...
     * @author Tadej
     */
    public class ControllerButton extends Sprite
    {
        public static const BUTTON_STANDARD:String = "standardButton";
        public static const BUTTON_BACK:String = "backButton";
        public static const BUTTON_START:String = "startButton";
        public static const BUTTON_HAT:String = "hatButton";
        public static const BUTTON_BUMPER:String = "bumperButton";
        
        protected var normal:Image;
        protected var pressed:Image;
        protected var mButtonID:int;
        protected var mType:String;
        protected var isPressed:Boolean = false;
        protected var btnRotation:Number = 0;
        
        public function ControllerButton(type:String, id:int, x:Number = 0, y:Number = 0, rotation:Number = 0) 
        {
            mType = type;
            mButtonID = id;
            this.x = x;
            this.y = y;
            btnRotation = rotation;
            
            init();
        }
        
        protected function init()
        {
            switch(mType) {
                case BUTTON_STANDARD:
                    normal = new Image(Texture.fromAsset("assets/controller/button.png"));
                    pressed = new Image(Texture.fromAsset("assets/controller/button-pressed.png"));
                    break;
                case BUTTON_BACK:
                    normal = new Image(Texture.fromAsset("assets/controller/back.png"));
                    pressed = new Image(Texture.fromAsset("assets/controller/back-pressed.png"));
                    break;
                case BUTTON_START:
                    normal = new Image(Texture.fromAsset("assets/controller/start.png"));
                    pressed = new Image(Texture.fromAsset("assets/controller/start-pressed.png"));
                    break;
                case BUTTON_HAT:
                    normal = new Image(Texture.fromAsset("assets/controller/d-pad.png"));
                    pressed = new Image(Texture.fromAsset("assets/controller/d-pad-pressed.png"));
                    break;
                case BUTTON_BUMPER:
                    normal = new Image(Texture.fromAsset("assets/controller/shoulder.png"));
                    pressed = new Image(Texture.fromAsset("assets/controller/shoulder-pressed.png"));
                    break;
            }
            
            normal.rotation = pressed.rotation = btnRotation;
            
            normal.center();
            pressed.center();
            this.addChild(normal);
            this.addChild(pressed);
            
            normal.visible = pressed.visible = false;
        }
        
        public function onTick()
        {
            if (isPressed) {
                pressed.visible = true;
                normal.visible = false;
            } else {
                normal.visible = true;
                pressed.visible = false;
            }
        }
        
        public function setPressed(pressed:Boolean) { isPressed = pressed; }
        
        public function get type():String { return mType; }
        
        public function get buttonID():int { return mButtonID; }
        
    }
    
}