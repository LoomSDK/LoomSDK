package
{
    import loom.gameframework.AnimatedComponent;

    import loom2d.Loom2D;
    import loom2d.display.Image;
    import loom2d.ui.TextureAtlasManager;

    /**
     * A class that encapsulates a sprite. This wrapping is required to be able to bind
     * the position and scale values of our mover classes to the correct sprite's position and scale properties.
     *
     * The renderer and the mover objects are added as components to a LoomGameObject which makes
     * binding mover position, rotation and scale values directly to the same renderer properties possible.
     */
    public class PongRenderer extends AnimatedComponent
    {
        var game:Pong;                      ///< The game for which this class renders an object.
        public var image:Image;             ///< The image that the class must render.
        var texture:String;                 ///< The frame name this renderer must use for the sprite object.

        /**
         * The constructor of this class must be called with a texture parameter for the sprite.
         * This class assumes that all sprites reside in pongSprites.
         * 
         * @param   _texture:String The file name of the sprite within pongSprites.
         */
        public function PongRenderer(_texture:String, _game:Pong)
        {
            game    = _game;
            texture = _texture;
        }

        /**
         * Built in setter to propagate x position value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set x(value:Number):void
        {
            if(image)
                image.x = value;
        }

        /**
         * Built in setter to propagate y position value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set y(value:Number):void
        {
            if(image)
                image.y = value;
        }

        /**
         * Built in setter to propagate scale value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set scale(value:Number):void
        {
            if(image)
                image.scale = value;
        }

        /**
         * Built in setter to propagate rotation value changes for data binding as a component.
         *
         * @param   value:Number    The value to set.
         */
        public function set rotation(value:Number):void
        {
            if(image)
                image.rotation = value;
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

            image = new Image(TextureAtlasManager.getTexture("pongSprites", texture));
            Loom2D.stage.addChild(image);

            return true;
        }

        /**
         * This is meant to remove the sprite from the main layer.
         */
        protected function onRemove():void
        {
            Loom2D.stage.removeChild(image);

            super.onRemove();
        }
    }
}