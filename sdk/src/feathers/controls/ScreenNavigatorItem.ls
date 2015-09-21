/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls
{
    import system.errors.IllegalOperationError;

    import loom2d.display.DisplayObject;

    /**
     * Data for an individual screen that will be used by a `ScreenNavigator`
     * object.
     *
     * @see http://wiki.starling-framework.org/feathers/screen-navigator
     * @see feathers.controls.ScreenNavigator
     */
    public class ScreenNavigatorItem
    {
        /**
         * Constructor.
         */
        public function ScreenNavigatorItem(screen:Object = null, events:Dictionary.<String, Object> = null, properties:Dictionary.<String, Object> = null)
        {
            this.screen = screen;
            this.events = events ? events : {};
            this.properties = properties ? properties : {};
        }
        
        /**
         * A Starling DisplayObject, a Type that may be instantiated to create
         * a DisplayObject, or a Function that returns a DisplayObject.
         */
        public var screen:Object;
        
        /**
         * A hash of events to which the ScreenNavigator will listen. Keys in
         * the hash are event types (or the property name of an `ISignal`),
         * and values are one of two possible types. If the value is a
         * `String`, it must refer to a screen ID for the
         * `ScreenNavigator` to display. If the value is a
         * `Function`, it must be a listener for the screen's event
         * or `ISignal`.
         */
        public var events:Dictionary.<String, Object>;
        
        /**
         * A hash of properties to set on the screen.
         */
        public var properties:Dictionary.<String, Object>;
        
        /**
         * Creates and instance of the screen type (or uses the screen directly
         * if it isn't a class).
         */
        /*internal*/ public function getScreen():DisplayObject
        {
            var screenInstance:DisplayObject;

            Debug.assert(this.screen != null, "No screen specified!");
            
            if(this.screen as Type)
            {
                var screenType:Type = this.screen as Type;
                screenInstance = screenType.getConstructor().invoke() as DisplayObject;
                Debug.assert(screenInstance, "Type isn't a subclass of DisplayObject");
            }
            else if(this.screen as Function)
            {
                screenInstance = DisplayObject((this.screen as Function).call());
            }
            else if(this.screen as DisplayObject)
            {
                screenInstance = DisplayObject(this.screen);
            }
            else
            {
                Debug.assert("ScreenNavigatorItem \"screen\" must be a Type, a Function, or a Starling display object.");
            }
            

            if(this.properties)
            {
                Dictionary.mapToObject(this.properties, screenInstance);
            }
            
            return screenInstance;
        }
    }
}