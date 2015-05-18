/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.core
{

    /**
     * An interface for something that has a label.
     */
    public interface ILabel extends IFeathersControl
    {
        /**
         * Indicates if the IToggle is selected or not.
         */
        function get label():String;
        
        /**
         * @private
         */
        function set label(value:String):void;
    }
}