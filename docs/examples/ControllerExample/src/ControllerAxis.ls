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
    public class ControllerAxis extends ControllerButton
    {
        public static const BUTTON_STICK:String = "stickButton";
        
        private var stick:Image;
        
        private var maxOffset:Number = 40;
        private var myValue:Number = 0;
        private var mxValue:Number = 0;
        
        public function ControllerAxis(type:String, id:int, x:Number = 0, y:Number = 0, rotation:Number = 0) 
        {
            super(type, id, x, y, rotation);
        }
        
        override protected function init()
        {
            normal = new Image(Texture.fromAsset("assets/controller/stick.png"));
            pressed = new Image(Texture.fromAsset("assets/controller/stick-pressed.png"));
            super.init();
        }
        
        override public function onTick()
        {
            var xStick = mxValue < 0 ? -(mxValue / ( -32768)) : mxValue / 32767;
            var yStick = myValue < 0 ? -(myValue / ( -32768)) : myValue / 32767;
            
            normal.x = pressed.x = maxOffset * xStick;
            normal.y = pressed.y = maxOffset * yStick;
            
            super.onTick();
        }
        
        public function get yValue():Number { return myValue; }
        public function get xValue():Number    { return myValue; }
        public function set yValue(value:Number):void
        {
            myValue = value;
        }
        public function set xValue(value:Number):void
        { 
            mxValue = value;
        }
    }
    
}