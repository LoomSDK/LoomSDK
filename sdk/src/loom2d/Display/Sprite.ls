package loom2d.display 
{
    import loom2d.math.Rectangle;

    /**
     * In Starling, this class adds clip rect and flattening support. In Loom, it's the
     * topmost container class.
     */
    [Native(managed)]
    public native class Sprite extends DisplayObjectContainer
    {
        protected var _clipRect:Rectangle = null;

        public function get clipRect():Rectangle
        {
            return _clipRect;
        }

        public function set clipRect(value:Rectangle):void
        {            
            if(value)
            {
                _clipRect = value.clone();
                setClipRect(value.x, value.y, value.width, value.height);
            }
            else
            {
                _clipRect = null;
                setClipRect(0,0,0,0);
            }
        }

        public function flatten():void
        {
            Debug.assert(false, "Not yet implemented.");
        }

        public function unflatten():void
        {
            Debug.assert(false, "Not yet implemented.");            
        }
    }
    
}