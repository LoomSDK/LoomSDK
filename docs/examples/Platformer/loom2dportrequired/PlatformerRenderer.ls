package
{
    import cocos2d.CCSprite;
    import cocos2d.CCSpriteFrame;
    import cocos2d.CCSpriteFrameCache;
    import cocos2d.CCNode;
    import loom.gameframework.AnimatedComponent;

    /**
     * A class that encapsulates a sprite. This wrapping is required to be able to bind
     * the position and scale values of our mover classes to the correct sprite's position and scale properties.
     *
     * The renderer and the mover objects are added as components to a LoomGameObject which makes
     * binding mover position, rotation and scale values directly to the same renderer properties possible.
     */
    public class PlatformerRenderer extends AnimatedComponent
    {
        var parent:CCNode;
        var frame:CCSpriteFrame;            ///< The sprite frame the class uses to render the sprite.
        public var sprite:CCSprite;         ///< The sprite that the class must render.
        var _texture:String;                 ///< The frame name this renderer must use for the sprite object.

        /**
         * The constructor of this class must be called with a texture parameter for the sprite.
         * This class assumes that all sprites reside in pongSprites.
         * 
         * @param   _texture:String The file name of the sprite within pongSprites.
         */
        public function PlatformerRenderer(__texture:String, nodeParent:CCNode) // , _game:Pong)
        {
            //game    = _game;
            parent=nodeParent;
            _texture = __texture;

            frame = CCSpriteFrameCache.sharedSpriteFrameCache().spriteFrameByName(_texture);

            sprite = CCSprite.createWithSpriteFrame(frame);
        }

        /**
         * Built in setter to propagate x position value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set x(value:Number):void
        {
            if(sprite)
                sprite.setPositionX(value);
        }

        /**
         * Built in setter to propagate y position value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set y(value:Number):void
        {
            if(sprite)
                sprite.setPositionY(value);
        }

        /**
         * Built in setter to propagate scale value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set scaleX(value:Number):void
        {
            if(sprite)
                sprite.setScaleX(value);
        }

        /**
         * Built in setter to propagate scale value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set scaleY(value:Number):void
        {
            if(sprite)
                sprite.setScaleY(value);
        }


        /**
         * Built in setter to propagate rotation value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set rotation(value:Number):void
        {
            if(sprite)
                sprite.setRotation(value);
        }

        public function set texture(value:String):void
        {
            if(value != _texture)
            {
                _texture = value;

                var nextFrame = CCSpriteFrameCache.sharedSpriteFrameCache().spriteFrameByName(_texture);
                if (nextFrame)
                    sprite.setDisplayFrame(nextFrame);
            }
        }

        /**
         * Executed when this renderer is added. It create a sprites and sets the correct texture for it.
         *
         * @return  Boolean Returns true if the sprite was successfully added to the sprite batch.
         */
        protected function onAdd():Boolean
        {
            if(!super.onAdd())
                return false;

            parent.addChild(sprite);

            return true;
        }

        /**
         * This is meant to remove the sprite from the main layer.
         */
        protected function onRemove():void
        {
            parent.removeChild(sprite);
            //game.layer.removeChild(sprite);

            super.onRemove();
        }
    }
}