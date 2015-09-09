package 
{
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    
    /**
     * ...
     * @author Tadej
     */
    public class StickIndicator 
    {
        private var indicator:Image;
        
        public var x:Number = 0;
        public var y:Number = 0;
        public var xOffset:Number = 0;
        public var yOffset:Number = 0;
        
        private var offsetMax:Number = 20;
        
        public function StickIndicator(parent:DisplayObjectContainer) 
        {
            indicator = new Image(Texture.fromAsset("assets/logo.png"));
            indicator.center();
            parent.addChild(indicator);
        }
        
        public function onTick() {
            indicator.x = x - (-xOffset) * offsetMax;
            indicator.y = y - (-yOffset) * offsetMax;
        }
    }
    
}