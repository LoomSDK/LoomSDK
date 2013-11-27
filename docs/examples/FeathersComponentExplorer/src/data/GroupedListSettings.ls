/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/

package data
{
    public class GroupedListSettings
    {
        public static const STYLE_NORMAL:String = "normal";
        public static const STYLE_INSET:String = "inset";

        public function GroupedListSettings()
        {
        }

        public var isSelectable:Boolean = true;
        public var hasElasticEdges:Boolean = true;
        public var style:String = STYLE_NORMAL;
    }
}
