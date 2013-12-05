package
{
	import loom2d.display.DisplayObjectContainer;
	import loom2d.ui.TextureAtlasSprite;
	
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
        var parent:DisplayObjectContainer;
        public var sprite:TextureAtlasSprite;         ///< The sprite that the class must render.
        var _texture:String;                 ///< The frame name this renderer must use for the sprite object.
        var _atlasName:String;

        /**
         * The constructor of this class must be called with a texture parameter for the sprite.
         * This class assumes that all sprites reside in pongSprites.
         * 
         * @param   _texture:String The file name of the sprite within pongSprites.
         */
        public function PlatformerRenderer(__atlasName:String, __texture:String, nodeParent:DisplayObjectContainer) // , _game:Pong)
        {
            //game    = _game;
            parent=nodeParent;
            _atlasName = __atlasName;
            _texture = __texture;

            sprite = new TextureAtlasSprite();
            sprite.atlasName = _atlasName;
            sprite.textureName = _texture;
            sprite.center();
        }

        /**
         * Built in setter to propagate x position value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set x(value:Number):void
        {
            if(sprite)
                sprite.x = value;
        }

        /**
         * Built in setter to propagate y position value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set y(value:Number):void
        {
            if(sprite)
                sprite.y = value;
        }

        /**
         * Built in setter to propagate scale value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set scaleX(value:Number):void
        {
            if(sprite)
                sprite.scaleX = value;
        }

        /**
         * Built in setter to propagate scale value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set scaleY(value:Number):void
        {
            if(sprite)
                sprite.scaleY = value;
        }


        /**
         * Built in setter to propagate rotation value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set rotation(value:Number):void
        {
            if(sprite)
                sprite.rotation = value;
        }

        public function set atlasName(value:String):void
        {
            if(value != _atlasName)
            {
                _atlasName = value;
                sprite.atlasName = value;
                sprite.center();
            }
        }

        public function set texture(value:String):void
        {
            if(value != _texture)
            {
                _texture = value;
                sprite.textureName = value;
                sprite.center();
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