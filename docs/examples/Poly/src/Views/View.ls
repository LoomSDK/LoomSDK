package poly.ui
{
    import loom2d.display.DisplayObjectContainer;

    public delegate ViewCallback():void;

    /**
     * Base view class; convenience callbacks to trigger Transitions and 
     * sequence adding/removing from parent.
     */
    class View extends DisplayObjectContainer
    {
        public var onEnter:ViewCallback;
        public var onExit:ViewCallback;

        public function enter(owner:DisplayObjectContainer):void
        {
            owner.addChild(this);
            onEnter();
        }

        public function exit():void
        {
            if(parent)
            {
                parent.removeChild(this);
                onExit();
            }
        }

    }
}