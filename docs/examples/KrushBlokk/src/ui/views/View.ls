package ui.views
{
    import loom2d.display.DisplayObjectContainer;
    import loom2d.textures.Texture;
    import loom2d.textures.TextureSmoothing;

    public delegate ViewCallback():void;

    /**
    * Base view class; convenience callbacks to trigger Transitions and 
    * sequence adding/removing from parent.
    */
    class View extends DisplayObjectContainer
    {
        public var onEnter:ViewCallback;
        public var onExit:ViewCallback;
        
        public function init() {}
        public function resize(w:Number, h:Number) {}
        public function tick() {}
        public function render() {}
        
        public function enter(owner:DisplayObjectContainer)
        {
            owner.addChild(this);
            onEnter();
        }
        
        public function exit()
        {
            if (parent) parent.removeChild(this);
            onExit();
        }
        
    }
}