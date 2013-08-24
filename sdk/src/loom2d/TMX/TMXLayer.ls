package loom2d.tmx
{
    import loom2d.display.Sprite;
    /**
     * 
     */
    public class TMXLayer extends Sprite
    {
        private var _layerData = [];
        private var _layerHolder:Sprite = new Sprite;
        
        public function TMXLayer(data:Vector.<int>):void
        {
            _layerData = data;
        }
        
        public function getData():Vector.<int>
        {
            return _layerData;
        }
        
        public function getHolder():Sprite
        {
            return _layerHolder;
        }
        
        public function drawLayer():void
        {
            addChild(_layerHolder);
        }
    }
}