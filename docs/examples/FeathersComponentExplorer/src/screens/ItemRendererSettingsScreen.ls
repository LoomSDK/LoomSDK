/*
Feathers
Copyright 2012-2013 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/

package screens
{
    import feathers.controls.Button;
    import feathers.controls.GroupedList;
    import feathers.controls.PanelScreen;
    import feathers.controls.PickerList;
    import feathers.controls.ToggleSwitch;
    import feathers.controls.renderers.BaseDefaultItemRenderer;
    import feathers.data.HierarchicalCollection;
    import feathers.data.ListCollection;
    import feathers.events.FeathersEventType;
    import data.ItemRendererSettings;
    import feathers.layout.AnchorLayout;
    import feathers.layout.AnchorLayoutData;

    import loom2d.display.DisplayObject;
    import loom2d.events.Event;

    [Event(name="complete",type="loom2d.events.Event")]

    public class ItemRendererSettingsScreen extends PanelScreen
    {
        private static const GAP_LABEL_INFINITE:String = "Fill Available Space";
        private static const GAP_LABEL_DEFAULT:String = "No Fill";

        public function ItemRendererSettingsScreen()
        {
            this.addEventListener(FeathersEventType.INITIALIZE, initializeHandler);
        }

        public var settings:ItemRendererSettings;

        private var _list:GroupedList;
        private var _backButton:Button;
        private var _gapPicker:PickerList;
        private var _hasIconToggle:ToggleSwitch;
        private var _hasAccessoryToggle:ToggleSwitch;
        private var _layoutOrderPicker:PickerList;
        private var _iconPositionPicker:PickerList;
        private var _accessoryPositionPicker:PickerList;
        private var _accessoryTypePicker:PickerList;
        private var _accessoryGapPicker:PickerList;
        private var _horizontalAlignPicker:PickerList;
        private var _verticalAlignPicker:PickerList;

        protected function initializeHandler(event:Event):void
        {
            this.layout = new AnchorLayout();

            this._hasIconToggle = new ToggleSwitch();
            this._hasIconToggle.isSelected = this.settings.hasIcon;
            this._hasIconToggle.addEventListener(Event.CHANGE, hasIconToggle_changeHandler);

            this._iconPositionPicker = new PickerList();
            this._iconPositionPicker.typicalItem = Button.ICON_POSITION_RIGHT_BASELINE;
            this._iconPositionPicker.dataProvider = new ListCollection(new <String>
            [
                Button.ICON_POSITION_TOP,
                Button.ICON_POSITION_RIGHT,
                Button.ICON_POSITION_BOTTOM,
                Button.ICON_POSITION_LEFT,
                Button.ICON_POSITION_LEFT_BASELINE,
                Button.ICON_POSITION_RIGHT_BASELINE,
                //Button.ICON_POSITION_MANUAL,
            ]);
            this._iconPositionPicker.listProperties[ "typicalItem" ] = Button.ICON_POSITION_RIGHT_BASELINE;
            this._iconPositionPicker.selectedItem = this.settings.iconPosition;
            this._iconPositionPicker.addEventListener(Event.CHANGE, iconPositionPicker_changeHandler);

            this._gapPicker = new PickerList();
            this._gapPicker.dataProvider = new ListCollection(
            [
                { label: GAP_LABEL_INFINITE, value: true },
                { label: GAP_LABEL_DEFAULT, value: false },
            ]);
            this._gapPicker.typicalItem = this._gapPicker.dataProvider.getItemAt(0);
            this._gapPicker.listProperties[ "typicalItem" ] = this._gapPicker.dataProvider.getItemAt(0);
            this._gapPicker.selectedItem = this._gapPicker.dataProvider.getItemAt(this.settings.useInfiniteGap ? 0 : 1);
            this._gapPicker.addEventListener(Event.CHANGE, gapPicker_changeHandler);

            this._hasAccessoryToggle = new ToggleSwitch();
            this._hasAccessoryToggle.isSelected = this.settings.hasAccessory;
            this._hasAccessoryToggle.addEventListener(Event.CHANGE, hasAccessoryToggle_changeHandler);

            this._accessoryTypePicker = new PickerList();
            this._accessoryTypePicker.typicalItem = ItemRendererSettings.ACCESSORY_TYPE_DISPLAY_OBJECT;
            this._accessoryTypePicker.dataProvider = new ListCollection(new <String>
            [
                ItemRendererSettings.ACCESSORY_TYPE_DISPLAY_OBJECT,
                ItemRendererSettings.ACCESSORY_TYPE_TEXTURE,
                ItemRendererSettings.ACCESSORY_TYPE_LABEL,
            ]);
            this._accessoryTypePicker.listProperties[ "typicalItem" ] = ItemRendererSettings.ACCESSORY_TYPE_DISPLAY_OBJECT;
            this._accessoryTypePicker.selectedItem = this.settings.accessoryType;
            this._accessoryTypePicker.addEventListener(Event.CHANGE, accessoryTypePicker_changeHandler);

            this._accessoryPositionPicker = new PickerList();
            this._accessoryPositionPicker.typicalItem = BaseDefaultItemRenderer.ACCESSORY_POSITION_BOTTOM;
            this._accessoryPositionPicker.dataProvider = new ListCollection(new <String>
            [
                BaseDefaultItemRenderer.ACCESSORY_POSITION_TOP,
                BaseDefaultItemRenderer.ACCESSORY_POSITION_RIGHT,
                BaseDefaultItemRenderer.ACCESSORY_POSITION_BOTTOM,
                BaseDefaultItemRenderer.ACCESSORY_POSITION_LEFT,
                //BaseDefaultItemRenderer.ACCESSORY_POSITION_MANUAL,
            ]);
            this._accessoryPositionPicker.listProperties[ "typicalItem" ] = BaseDefaultItemRenderer.ACCESSORY_POSITION_BOTTOM;
            this._accessoryPositionPicker.selectedItem = this.settings.accessoryPosition;
            this._accessoryPositionPicker.addEventListener(Event.CHANGE, accessoryPositionPicker_changeHandler);

            this._accessoryGapPicker = new PickerList();
            this._accessoryGapPicker.dataProvider = new ListCollection(
            [
                { label: GAP_LABEL_INFINITE, value: true },
                { label: GAP_LABEL_DEFAULT, value: false },
            ]);
            this._accessoryGapPicker.typicalItem = this._accessoryGapPicker.dataProvider.getItemAt(0);
            this._accessoryGapPicker.listProperties[ "typicalItem" ] = this._accessoryGapPicker.dataProvider.getItemAt(0);
            this._accessoryGapPicker.selectedItem = this._accessoryGapPicker.dataProvider.getItemAt(this.settings.useInfiniteAccessoryGap ? 0 : 1);
            this._accessoryGapPicker.addEventListener(Event.CHANGE, accessoryGapPicker_changeHandler);

            this._layoutOrderPicker = new PickerList();
            this._layoutOrderPicker.typicalItem = BaseDefaultItemRenderer.LAYOUT_ORDER_LABEL_ACCESSORY_ICON;
            this._layoutOrderPicker.dataProvider = new ListCollection(new <String>
            [
                BaseDefaultItemRenderer.LAYOUT_ORDER_LABEL_ICON_ACCESSORY,
                BaseDefaultItemRenderer.LAYOUT_ORDER_LABEL_ACCESSORY_ICON,
            ]);
            this._layoutOrderPicker.listProperties[ "typicalItem" ] = BaseDefaultItemRenderer.LAYOUT_ORDER_LABEL_ACCESSORY_ICON;
            this._layoutOrderPicker.selectedItem = this.settings.layoutOrder;
            this._layoutOrderPicker.addEventListener(Event.CHANGE, layoutOrderPicker_changeHandler);

            this._horizontalAlignPicker = new PickerList();
            this._horizontalAlignPicker.dataProvider = new ListCollection(new <String>
            [
                Button.HORIZONTAL_ALIGN_LEFT,
                Button.HORIZONTAL_ALIGN_CENTER,
                Button.HORIZONTAL_ALIGN_RIGHT,
            ]);
            this._horizontalAlignPicker.typicalItem = Button.HORIZONTAL_ALIGN_CENTER;
            this._horizontalAlignPicker.listProperties[ "typicalItem" ] = Button.HORIZONTAL_ALIGN_CENTER;
            this._horizontalAlignPicker.selectedItem = this.settings.horizontalAlign;
            this._horizontalAlignPicker.addEventListener(Event.CHANGE, horizontalAlignPicker_changeHandler);

            this._verticalAlignPicker = new PickerList();
            this._verticalAlignPicker.dataProvider = new ListCollection(new <String>
            [
                Button.VERTICAL_ALIGN_TOP,
                Button.VERTICAL_ALIGN_MIDDLE,
                Button.VERTICAL_ALIGN_BOTTOM,
            ]);
            this._verticalAlignPicker.typicalItem = Button.VERTICAL_ALIGN_MIDDLE;
            this._verticalAlignPicker.listProperties[ "typicalItem" ] = Button.VERTICAL_ALIGN_MIDDLE;
            this._verticalAlignPicker.selectedItem = this.settings.verticalAlign;
            this._verticalAlignPicker.addEventListener(Event.CHANGE, verticalAlignPicker_changeHandler);

            this._list = new GroupedList();
            this._list.nameList.add(GroupedList.ALTERNATE_NAME_INSET_GROUPED_LIST);
            this._list.isSelectable = false;
            this._list.dataProvider = new HierarchicalCollection(
            [
                {
                    header: "Layout",
                    children:
                    [
                        { label: "layoutOrder", accessory: this._layoutOrderPicker },
                        { label: "horizontalAlign", accessory: this._horizontalAlignPicker },
                        { label: "verticalAlign", accessory: this._verticalAlignPicker },
                    ]
                },
                {
                    header: "Icon",
                    children:
                    [
                        { label: "Has Icon", accessory: this._hasIconToggle },
                        { label: "iconPosition", accessory: this._iconPositionPicker },
                        { label: "gap", accessory: this._gapPicker },
                    ]
                },
                {
                    header: "Accessory",
                    children:
                    [
                        { label: "Has Accessory", accessory: this._hasAccessoryToggle },
                        { label: "Accessory Type", accessory: this._accessoryTypePicker },
                        { label: "accessoryPosition", accessory: this._accessoryPositionPicker },
                        { label: "accessoryGap", accessory: this._accessoryGapPicker },
                    ]
                },
            ]);
            this._list.layoutData = new AnchorLayoutData(0, 0, 0, 0);
            this._list.clipContent = false;
            //this._list.autoHideBackground = true;
            this.addChild(this._list);

            this._backButton = new Button();
            this._backButton.nameList.add(Button.ALTERNATE_NAME_BACK_BUTTON);
            this._backButton.label = "Back";
            this._backButton.addEventListener(Event.TRIGGERED, backButton_triggeredHandler);

            this.headerProperties[ "title" ] = "Item Renderer Settings";
            this.headerProperties[ "leftItems" ] = [ this._backButton ];
            this.backButtonHandler = this.onBackButton;
        }

        private function onBackButton():void
        {
            this.dispatchEventWith(Event.COMPLETE);
        }

        private function hasIconToggle_changeHandler(event:Event):void
        {
            this.settings.hasIcon = this._hasIconToggle.isSelected;
        }

        private function iconPositionPicker_changeHandler(event:Event):void
        {
            this.settings.iconPosition = this._iconPositionPicker.selectedItem as String;
        }

        private function gapPicker_changeHandler(event:Event):void
        {
            this.settings.useInfiniteGap = this._gapPicker.selectedIndex == 0;
        }

        private function hasAccessoryToggle_changeHandler(event:Event):void
        {
            this.settings.hasAccessory = this._hasAccessoryToggle.isSelected;
        }

        private function accessoryTypePicker_changeHandler(event:Event):void
        {
            this.settings.accessoryType = this._accessoryTypePicker.selectedItem as String;
        }

        private function accessoryPositionPicker_changeHandler(event:Event):void
        {
            this.settings.accessoryPosition = this._accessoryPositionPicker.selectedItem as String;
        }

        private function accessoryGapPicker_changeHandler(event:Event):void
        {
            this.settings.useInfiniteAccessoryGap = this._accessoryGapPicker.selectedIndex == 0;
        }

        private function layoutOrderPicker_changeHandler(event:Event):void
        {
            this.settings.layoutOrder = this._layoutOrderPicker.selectedItem as String;
        }

        private function horizontalAlignPicker_changeHandler(event:Event):void
        {
            this.settings.horizontalAlign = this._horizontalAlignPicker.selectedItem as String;
        }

        private function verticalAlignPicker_changeHandler(event:Event):void
        {
            this.settings.verticalAlign = this._verticalAlignPicker.selectedItem as String;
        }

        private function backButton_triggeredHandler(event:Event):void
        {
            this.onBackButton();
        }
    }
}
