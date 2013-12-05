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
    import feathers.controls.ToggleSwitch;
    import feathers.data.ListCollection;
    import feathers.events.FeathersEventType;
    import data.ItemRendererSettings;
    import data.EmbeddedAssets;
    import feathers.layout.AnchorLayout;
    import feathers.layout.AnchorLayoutData;
    import feathers.system.DeviceCapabilities;

    import loom2d.Loom2D;
    import loom2d.display.DisplayObject;
    import loom2d.events.Event;

    [Event(name="complete",type="loom2d.events.Event")]
    [Event(name="showSettings",type="loom2d.events.Event")]

    public class ItemRendererScreen extends PanelScreen
    {
        public static const SHOW_SETTINGS:String = "showSettings";

        public function ItemRendererScreen()
        {
            this.addEventListener(FeathersEventType.INITIALIZE, initializeHandler);
        }

        public var settings:ItemRendererSettings = new ItemRendererSettings();

        private var _list:List;
        private var _backButton:Button;
        private var _settingsButton:Button;

        protected function initializeHandler(event:Event):void
        {
            this.layout = new AnchorLayout();

            this._list = new List();

            var item:Dictionary.<String, Object> = { text: "Primary Text" };
            this._list.itemRendererProperties[ "labelField" ] = "text";

            if(this.settings.hasIcon)
            {
                item[ "texture" ] = EmbeddedAssets.SKULL_ICON_LIGHT;

                this._list.itemRendererProperties[ "iconSourceField" ] = "texture";
                this._list.itemRendererProperties[ "iconPosition" ] = this.settings.iconPosition;
            }
            if(this.settings.hasAccessory)
            {
                switch(this.settings.accessoryType)
                {
                    case ItemRendererSettings.ACCESSORY_TYPE_LABEL:
                    {
                        item[ "secondaryText" ] = "Secondary Text";
                        this._list.itemRendererProperties[ "accessoryLabelField" ] = "secondaryText";
                        break;
                    }
                    case ItemRendererSettings.ACCESSORY_TYPE_TEXTURE:
                    {
                        item[ "accessoryTexture" ] = EmbeddedAssets.SKULL_ICON_LIGHT;
                        this._list.itemRendererProperties[ "accessorySourceField" ] = "accessoryTexture";
                        break;
                    }
                    default:
                    {
                        item[ "accessory" ] = new ToggleSwitch();
                        this._list.itemRendererProperties[ "accessoryField" ] = "accessory";
                    }
                }
                this._list.itemRendererProperties[ "accessoryPosition" ] = this.settings.accessoryPosition;
            }
            if(this.settings.useInfiniteGap)
            {
                this._list.itemRendererProperties[ "gap" ] = Number.POSITIVE_INFINITY;
            }
            else
            {
                this._list.itemRendererProperties[ "gap" ] = 20 * this.dpiScale;
            }
            if(this.settings.useInfiniteAccessoryGap)
            {
                this._list.itemRendererProperties[ "accessoryGap" ] = Number.POSITIVE_INFINITY;
            }
            else
            {
                this._list.itemRendererProperties[ "accessoryGap" ] = 20 * this.dpiScale;
            }
            this._list.itemRendererProperties[ "horizontalAlign" ] = this.settings.horizontalAlign;
            this._list.itemRendererProperties[ "verticalAlign" ] = this.settings.verticalAlign;
            this._list.itemRendererProperties[ "layoutOrder" ] = this.settings.layoutOrder;

            //ideally, styles like gap, accessoryGap, horizontalAlign,
            //verticalAlign, layoutOrder, iconPosition, and accessoryPosition
            //will be handled in the theme.
            //this is a special case because this screen is designed to
            //configure those styles at runtime

            this._list.dataProvider = new ListCollection([item]);
            this._list.layoutData = new AnchorLayoutData(0, 0, 0, 0);
            this._list.isSelectable = false;
            this._list.clipContent = false;
            //this._list.autoHideBackground = true;
            this.addChild(this._list);

            this.headerProperties[ "title" ] = "Item Renderer";

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
            this.headerProperties[ "rightItems" ] = [ _settingsButton ];
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
    }
}
