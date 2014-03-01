/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.skins
{
    import feathers.display.Scale3Image;
    import feathers.display.Scale9Image;
    import feathers.textures.Scale3Textures;
    import feathers.textures.Scale9Textures;

    import loom2d.display.DisplayObject;
    import loom2d.display.Image;
    import loom2d.display.Quad;
    import loom2d.textures.SubTexture;
    import loom2d.textures.Texture;

    /**
     * Values for each state are textures or colors, and the manager attempts to
     * reuse the existing display object that is passed in to getValueForState()
     * as the old value, if possible. Supports Image and Texture, Scale3Image
     * and Scale3Textures, Scale9Image and Scale9Textures, or Quad and uint
     * (color) value.
     *
     * Additional value type handlers may be added, or the default type
     * handlers may be replaced.
     */
    public class SmartDisplayObjectStateValueSelector extends StateWithToggleValueSelector
    {
        /**
         * The value type handler for type `loom2d.textures.Texture`.
         *
         * @see loom2d.textures.Texture
         */
        public static function textureValueTypeHandler(value:Texture, oldDisplayObject:DisplayObject = null):DisplayObject
        {
            var displayObject:Image = oldDisplayObject as Image;
            if(displayObject)
            {
                displayObject.texture = value;
                displayObject.readjustSize();
            }
            else
            {
                displayObject = new Image(value);
            }
            return displayObject;
        }


        /**
         * The value type handler for type `feathers.textures.Scale3Textures`.
         *
         * @see feathers.textures.Scale3Textures
         */
        public static function scale3TextureValueTypeHandler(value:Scale3Textures, oldDisplayObject:DisplayObject = null):DisplayObject
        {
            var displayObject:Scale3Image = oldDisplayObject as Scale3Image;
            if(displayObject)
            {
                displayObject.textures = value;
                displayObject.readjustSize();
            }
            else
            {
                displayObject = new Scale3Image(value);
            }
            return displayObject;
        }

        /**
         * The value type handler for type `feathers.textures.Scale9Textures`.
         *
         * @see feathers.textures.Scale9Textures
         */
        public static function scale9TextureValueTypeHandler(value:Scale9Textures, oldDisplayObject:DisplayObject = null):DisplayObject
        {            
            var displayObject:Scale9Image = oldDisplayObject as Scale9Image;
            if(displayObject)
            {
                displayObject.textures = value;
                displayObject.readjustSize();
            }
            else
            {
                displayObject = new Scale9Image(value);
            }

            return displayObject;
        }
        /**
         * The value type handler for type `uint` (a color to display
         * by a quad).
         */
        public static function uintValueTypeHandler(value:uint, oldDisplayObject:DisplayObject = null):DisplayObject
        {
            var displayObject:Quad = oldDisplayObject as Quad;
            if(!displayObject)
            {
                displayObject = new Quad(100, 100, value);
            }
            displayObject.color = value;
            return displayObject;
        }

        /**
         * Constructor.
         */
        public function SmartDisplayObjectStateValueSelector()
        {
            this.setValueTypeHandler(Texture, textureValueTypeHandler);
            this.setValueTypeHandler(SubTexture, textureValueTypeHandler);
            this.setValueTypeHandler(Scale9Textures, scale9TextureValueTypeHandler);
            this.setValueTypeHandler(Scale3Textures, scale3TextureValueTypeHandler);
            this.setValueTypeHandler(uint, uintValueTypeHandler);
        }

        /**
         * @private
         */
        protected var _displayObjectProperties:Dictionary.<String, Object>;

        /**
         * Optional properties to set on the Scale9Image instance.
         *
         * @see feathers.display.Scale9Image
         */
        public function get displayObjectProperties():Dictionary.<String, Object>
        {
            if(!this._displayObjectProperties)
            {
                this._displayObjectProperties = {};
            }
            return this._displayObjectProperties;
        }

        /**
         * @private
         */
        public function set displayObjectProperties(value:Dictionary.<String, Object>):void
        {
            this._displayObjectProperties = value;
        }

        /**
         * @private
         */
        protected var _handlers:Dictionary = new Dictionary.<String, Object>(true);

        /**
         * @private
         */
        override public function setValueForState(value:Object, state:Object, isSelected:Boolean = false):void
        {
            const type:Type = value.getType();
            if(this._handlers[type] == null)
            {
                throw new ArgumentError("Handler for value type " + type + " has not been set.");
            }
            super.setValueForState(value, state, isSelected);
        }

        /**
         * @private
         */
        override public function updateValue(target:Object, state:Object, oldValue:Object = null):Object
        {
            const value:Object = super.updateValue(target, state);
            if(!value)
            {
                return null;
            }

            var displayObject:DisplayObject = null;
            
            const typeHandler:Function = this.valueToValueTypeHandler(value);
            if(typeHandler != null)
            {
                displayObject = typeHandler.call(null, value, oldValue) as DisplayObject;
            }
            else
            {
                throw new ArgumentError("Invalid value: " + value);
            }

            Debug.assert(displayObject != null, "All value functions should return non-null values. Failure for type " + value.getTypeName());

            if(_displayObjectProperties)
                Dictionary.mapToObject(_displayObjectProperties, displayObject);

            return displayObject;
        }

        /**
         * Sets a function to handle updating a value of a specific type. The
         * function must have the following signature:
         *
         * `function(value:Object, oldDisplayObject:DisplayObject = null):DisplayObject`
         *
         * The `oldDisplayObject` is optional, and it may be of
         * a type that is different than what the function will return. If the
         * types do not match, the function should create a new object instead
         * of reusing the old display object.
         */
        public function setValueTypeHandler(type:Type, handler:Function):void
        {
            this._handlers[type] = handler;
        }

        /**
         * Returns the function that handles updating a value of a specific type.
         */
        public function getValueTypeHandler(type:Type, handler:Function):Function
        {
            return this._handlers[type] as Function;
        }

        /**
         * Clears a value type handler.
         */
        public function clearValueTypeHandler(type:Type):void
        {
            this._handlers[type] = null;
            //delete this._handlers[type];
        }

        /**
         * @private
         */
        protected function valueToValueTypeHandler(value:Object):Function
        {
            const type:Type = value.getType();
            return this._handlers[type] as Function;
        }
    }
}
