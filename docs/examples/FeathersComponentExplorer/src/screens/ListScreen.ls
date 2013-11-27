/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/

package screens
{
    import feathers.controls.Button;
    import feathers.controls.List;
    import feathers.controls.PanelScreen;
    import feathers.controls.renderers.DefaultListItemRenderer;
    import feathers.controls.renderers.IListItemRenderer;
    import feathers.data.ListCollection;
    import feathers.events.FeathersEventType;
    import data.ListSettings;
    import feathers.layout.AnchorLayout;
    import feathers.layout.AnchorLayoutData;
    import feathers.system.DeviceCapabilities;

    import loom2d.Loom2D;
    import loom2d.display.DisplayObject;
    import loom2d.events.Event;

    [Event(name="complete",type="loom2d.events.Event")]
    [Event(name="showSettings",type="loom2d.events.Event")]

    public class ListScreen extends PanelScreen
    {
        public static const SHOW_SETTINGS:String = "showSettings";

        public function ListScreen()
        {
            super();
            this.addEventListener(FeathersEventType.INITIALIZE, initializeHandler);
        }

        public var settings:ListSettings;

        private var _list:List;
        private var _backButton:Button;
        private var _settingsButton:Button;
        
        protected function initializeHandler(event:Event):void
        {
            this.layout = new AnchorLayout();

            var items:Array = [];
            for(var i:int = 0; i < 150; i++)
            {
                var item:Object = {text: "Item " + (i + 1).toString()};
                items.push(item);
            }
            
            this._list = new List();
            this._list.dataProvider = new ListCollection(items);
            this._list.typicalItem = {text: "Item 1000"};
            this._list.isSelectable = this.settings.isSelectable;
            this._list.allowMultipleSelection = this.settings.allowMultipleSelection;
            this._list.hasElasticEdges = this.settings.hasElasticEdges;
            //optimization to reduce draw calls.
            //only do this if the header or other content covers the edges of
            //the list. otherwise, the list items may be displayed outside of
            //the list's bounds.
            this._list.clipContent = false;
            //this._list.autoHideBackground = true;
            this._list.itemRendererFactory = function():IListItemRenderer
            {
                var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();

                //enable the quick hit area to optimize hit tests when an item
                //is only selectable and doesn't have interactive children.
                renderer.isQuickHitAreaEnabled = true;

                renderer.labelField = "text";
                return renderer;
            };
            this._list.addEventListener(Event.CHANGE, list_changeHandler);
            this._list.layoutData = new AnchorLayoutData(0, 0, 0, 0);
            this.addChild(this._list);

            this.headerProperties[ "title" ] = "List";

            if(!DeviceCapabilities.isTablet())
            {
                this._backButton = new Button();
                this._backButton.nameList.add(Button.ALTERNATE_NAME_BACK_BUTTON);
                this._backButton.label = "Back";
                this._backButton.addEventListener(Event.TRIGGERED, backButton_triggeredHandler);
                this.headerProperties[ "leftItems" ] = [ _backButton ];
                this.backButtonHandler = this.onBackButton;
            }

            this._settingsButton = new Button();
            this._settingsButton.label = "Settings";
            this._settingsButton.addEventListener(Event.TRIGGERED, settingsButton_triggeredHandler);
            this.headerProperties[ "rightItems" ] = [ this._settingsButton ];
        }
        
        private function onBackButton():void
        {
            this.dispatchEventWith(Event.COMPLETE);
        }
        
        private function backButton_triggeredHandler(event:Event):void
        {
            this.onBackButton();
        }

        private function settingsButton_triggeredHandler(event:Event):void
        {
            this.dispatchEventWith(SHOW_SETTINGS);
        }

        private function list_changeHandler(event:Event):void
        {
            const selectedIndices:Vector.<int> = this._list.selectedIndices;
            trace("List onChange:", selectedIndices.length > 0 ? selectedIndices : this._list.selectedIndex);
        }
    }
}