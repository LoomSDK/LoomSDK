/*
 Copyright (c) 2012 Josh Tynjala

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */
package feathers.themes
{
    import feathers.controls.Button;
//    import feathers.controls.ButtonGroup;
//    import feathers.controls.Callout;
    import feathers.controls.Check;
    import feathers.controls.GroupedList;
    import feathers.controls.Header;
    import feathers.controls.ImageLoader;
    import feathers.controls.Label;
    import feathers.controls.List;
//    import feathers.controls.NumericStepper;
//    import feathers.controls.PageIndicator;
    import feathers.controls.Panel;
    import feathers.controls.PanelScreen;
//    import feathers.controls.PickerList;
    import feathers.controls.ProgressBar;
    import feathers.controls.Radio;
    import feathers.controls.Screen;
    import feathers.controls.ScrollContainer;
//    import feathers.controls.ScrollText;
    import feathers.controls.SimpleScrollBar;
//    import feathers.controls.Slider;
    import feathers.controls.TabBar;
    import feathers.controls.TextInput;
//    import feathers.controls.ToggleSwitch;
//    import feathers.controls.popups.CalloutPopUpContentManager;
//    import feathers.controls.popups.VerticalCenteredPopUpContentManager;
    import feathers.controls.renderers.BaseDefaultItemRenderer;
    import feathers.controls.renderers.DefaultGroupedListHeaderOrFooterRenderer;
    import feathers.controls.renderers.DefaultGroupedListItemRenderer;
    import feathers.controls.renderers.DefaultListItemRenderer;
//    import feathers.controls.text.StageTextTextEditor;
//    import feathers.controls.text.TextFieldTextEditor;
//    import feathers.controls.text.TextFieldTextRenderer;
    import feathers.core.DisplayListWatcher;
    import feathers.core.FeathersControl;
    import feathers.core.PopUpManager;
    import feathers.display.Scale3Image;
    import feathers.display.Scale9Image;
    import feathers.display.TiledImage;
    import feathers.layout.HorizontalLayout;
    import feathers.layout.VerticalLayout;
    import feathers.skins.SmartDisplayObjectStateValueSelector;
//    import feathers.skins.StandardIcons;
    import feathers.system.DeviceCapabilities;
    import feathers.textures.Scale3Textures;
    import feathers.textures.Scale9Textures;

    import feathers.text.DummyTextRenderer;
    import feathers.text.DummyTextEditor;
    import feathers.text.BitmapFontTextRenderer;
    import feathers.text.BitmapFontTextEditor;
    import feathers.text.BitmapFontTextFormat;
    import feathers.core.ITextEditor;
    import feathers.core.ITextRenderer;

    import loom2d.math.Rectangle;

    import loom2d.Loom2D;;
    import loom2d.display.DisplayObject;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.display.Image;
    import loom2d.display.Quad;
    import loom2d.events.Event;
    import loom2d.events.ResizeEvent;
    import loom2d.textures.Texture;
    import loom2d.textures.TextureAtlas;

    public class MetalWorksMobileTheme extends DisplayListWatcher
    {
/*        [Embed(source="/../assets/images/metalworks.png")]
        protected static const ATLAS_IMAGE:Class;

        [Embed(source="/../assets/images/metalworks.xml",mimeType="application/octet-stream")]
        protected static const ATLAS_XML:Class;

        [Embed(source="/../assets/fonts/SourceSansPro-Regular.ttf",fontName="SourceSansPro",mimeType="application/x-font",embedAsCFF="false")]
        protected static const SOURCE_SANS_PRO_REGULAR:Class;

        [Embed(source="/../assets/fonts/SourceSansPro-Semibold.ttf",fontName="SourceSansProSemibold",fontWeight="bold",mimeType="application/x-font",embedAsCFF="false")]
        protected static const SOURCE_SANS_PRO_SEMIBOLD:Class; */

        protected static const PRIMARY_BACKGROUND_COLOR:uint = 0x4a4137;
        protected static const LIGHT_TEXT_COLOR:uint = 0xe5e5e5;
        protected static const DARK_TEXT_COLOR:uint = 0x1a1816;
        protected static const SELECTED_TEXT_COLOR:uint = 0xff9900;
        protected static const DISABLED_TEXT_COLOR:uint = 0x8a8a8a;
        protected static const DARK_DISABLED_TEXT_COLOR:uint = 0x383430;
        protected static const LIST_BACKGROUND_COLOR:uint = 0x383430;
        protected static const TAB_BACKGROUND_COLOR:uint = 0x1a1816;
        protected static const TAB_DISABLED_BACKGROUND_COLOR:uint = 0x292624;
        protected static const MODAL_OVERLAY_COLOR:uint = 0x1a1816;
        protected static const GROUPED_LIST_HEADER_BACKGROUND_COLOR:uint = 0x2e2a26;
        protected static const GROUPED_LIST_FOOTER_BACKGROUND_COLOR:uint = 0x2e2a26;

        protected static const ORIGINAL_DPI_IPHONE_RETINA:int = 326;
        protected static const ORIGINAL_DPI_IPAD_RETINA:int = 264;

        protected static const DEFAULT_SCALE9_GRID:Rectangle = new Rectangle(5, 5, 22, 22);
        protected static const BUTTON_SCALE9_GRID:Rectangle = new Rectangle(5, 5, 50, 50);
        protected static const BUTTON_SELECTED_SCALE9_GRID:Rectangle = new Rectangle(8, 8, 44, 44);
        protected static const BACK_BUTTON_SCALE3_REGION1:Number = 24;
        protected static const BACK_BUTTON_SCALE3_REGION2:Number = 6;
        protected static const FORWARD_BUTTON_SCALE3_REGION1:Number = 6;
        protected static const FORWARD_BUTTON_SCALE3_REGION2:Number = 6;
        protected static const ITEM_RENDERER_SCALE9_GRID:Rectangle = new Rectangle(13, 0, 2, 82);
        protected static const INSET_ITEM_RENDERER_FIRST_SCALE9_GRID:Rectangle = new Rectangle(13, 13, 3, 70);
        protected static const INSET_ITEM_RENDERER_LAST_SCALE9_GRID:Rectangle = new Rectangle(13, 0, 3, 75);
        protected static const INSET_ITEM_RENDERER_SINGLE_SCALE9_GRID:Rectangle = new Rectangle(13, 13, 3, 62);
        protected static const TAB_SCALE9_GRID:Rectangle = new Rectangle(19, 19, 50, 50);
        protected static const SCROLL_BAR_THUMB_REGION1:int = 5;
        protected static const SCROLL_BAR_THUMB_REGION2:int = 14;

        public static const COMPONENT_NAME_PICKER_LIST_ITEM_RENDERER:String = "feathers-mobile-picker-list-item-renderer";

        protected static function textRendererFactory():ITextRenderer
        {
            return new BitmapFontTextRenderer();
        }

        protected static function textEditorFactory():ITextEditor
        {
            return new BitmapFontTextEditor();
        }

        protected static function stepperTextEditorFactory():ITextEditor
        {
            return new BitmapFontTextEditor();
        }

        protected static function popUpOverlayFactory():DisplayObject
        {
            const quad:Quad = new Quad(100, 100, MODAL_OVERLAY_COLOR);
            quad.alpha = 0.75;
            return quad;
        }

        public function MetalWorksMobileTheme(container:DisplayObjectContainer = null, scaleToDPI:Boolean = true)
        {
            if(!container)
            {
                container = Loom2D.stage;
            }
            super(container);
            this._scaleToDPI = scaleToDPI;
            this.initialize();
        }

        protected var _originalDPI:int;

        public function get originalDPI():int
        {
            return this._originalDPI;
        }

        protected var _scaleToDPI:Boolean;

        public function get scaleToDPI():Boolean
        {
            return this._scaleToDPI;
        }

        public var scale:Number = 1;

        public var headerTextFormat:BitmapFontTextFormat;

        public var smallUIDarkTextFormat:BitmapFontTextFormat;
        public var smallUILightTextFormat:BitmapFontTextFormat;
        public var smallUISelectedTextFormat:BitmapFontTextFormat;
        public var smallUILightDisabledTextFormat:BitmapFontTextFormat;
        public var smallUIDarkDisabledTextFormat:BitmapFontTextFormat;

        public var largeUIDarkTextFormat:BitmapFontTextFormat;
        public var largeUILightTextFormat:BitmapFontTextFormat;
        public var largeUISelectedTextFormat:BitmapFontTextFormat;
        public var largeUIDisabledTextFormat:BitmapFontTextFormat;

        public var largeDarkTextFormat:BitmapFontTextFormat;
        public var largeLightTextFormat:BitmapFontTextFormat;
        public var largeDisabledTextFormat:BitmapFontTextFormat;

        public var smallDarkTextFormat:BitmapFontTextFormat;
        public var smallLightTextFormat:BitmapFontTextFormat;
        public var smallDisabledTextFormat:BitmapFontTextFormat;
        public var smallLightTextFormatCentered:BitmapFontTextFormat;

        public var atlas:TextureAtlas;
        public var headerBackgroundSkinTexture:Texture;
        public var backgroundSkinTextures:Scale9Textures;
        public var backgroundInsetSkinTextures:Scale9Textures;
        public var backgroundDisabledSkinTextures:Scale9Textures;
        public var backgroundFocusedSkinTextures:Scale9Textures;
        public var buttonUpSkinTextures:Scale9Textures;
        public var buttonDownSkinTextures:Scale9Textures;
        public var buttonDisabledSkinTextures:Scale9Textures;
        public var buttonSelectedUpSkinTextures:Scale9Textures;
        public var buttonSelectedDisabledSkinTextures:Scale9Textures;
        public var buttonCallToActionUpSkinTextures:Scale9Textures;
        public var buttonCallToActionDownSkinTextures:Scale9Textures;
        public var buttonQuietUpSkinTextures:Scale9Textures;
        public var buttonQuietDownSkinTextures:Scale9Textures;
        public var buttonDangerUpSkinTextures:Scale9Textures;
        public var buttonDangerDownSkinTextures:Scale9Textures;
        public var buttonBackUpSkinTextures:Scale3Textures;
        public var buttonBackDownSkinTextures:Scale3Textures;
        public var buttonBackDisabledSkinTextures:Scale3Textures;
        public var buttonForwardUpSkinTextures:Scale3Textures;
        public var buttonForwardDownSkinTextures:Scale3Textures;
        public var buttonForwardDisabledSkinTextures:Scale3Textures;
        public var pickerListButtonIconTexture:Texture;
        public var tabDownSkinTextures:Scale9Textures;
        public var tabSelectedSkinTextures:Scale9Textures;
        public var tabSelectedDisabledSkinTextures:Scale9Textures;
        public var pickerListItemSelectedIconTexture:Texture;
        public var radioUpIconTexture:Texture;
        public var radioDownIconTexture:Texture;
        public var radioDisabledIconTexture:Texture;
        public var radioSelectedUpIconTexture:Texture;
        public var radioSelectedDownIconTexture:Texture;
        public var radioSelectedDisabledIconTexture:Texture;
        public var checkUpIconTexture:Texture;
        public var checkDownIconTexture:Texture;
        public var checkDisabledIconTexture:Texture;
        public var checkSelectedUpIconTexture:Texture;
        public var checkSelectedDownIconTexture:Texture;
        public var checkSelectedDisabledIconTexture:Texture;
        public var pageIndicatorNormalSkinTexture:Texture;
        public var pageIndicatorSelectedSkinTexture:Texture;
        public var itemRendererUpSkinTextures:Scale9Textures;
        public var itemRendererSelectedSkinTextures:Scale9Textures;
        public var insetItemRendererFirstUpSkinTextures:Scale9Textures;
        public var insetItemRendererFirstSelectedSkinTextures:Scale9Textures;
        public var insetItemRendererLastUpSkinTextures:Scale9Textures;
        public var insetItemRendererLastSelectedSkinTextures:Scale9Textures;
        public var insetItemRendererSingleUpSkinTextures:Scale9Textures;
        public var insetItemRendererSingleSelectedSkinTextures:Scale9Textures;
        public var backgroundPopUpSkinTextures:Scale9Textures;
        public var calloutTopArrowSkinTexture:Texture;
        public var calloutRightArrowSkinTexture:Texture;
        public var calloutBottomArrowSkinTexture:Texture;
        public var calloutLeftArrowSkinTexture:Texture;
        public var verticalScrollBarThumbSkinTextures:Scale3Textures;
        public var horizontalScrollBarThumbSkinTextures:Scale3Textures;

        override public function dispose():void
        {
            if(this.root)
            {
                this.root.removeEventListener(Event.ADDED_TO_STAGE, root_addedToStageHandler);
            }
            if(this.atlas)
            {
                this.atlas.dispose();
                this.atlas = null;
            }
            super.dispose();
        }

        protected function initializeRoot():void
        {
            if(this.root != this.root.stage)
            {
                trace("Aborting due to not knowing properly about Stage!");
                return;
            }

            this.root.stage.color = PRIMARY_BACKGROUND_COLOR;
        }

        protected function initialize():void
        {
            const scaledDPI:int = DeviceCapabilities.dpi / Loom2D.contentScaleFactor;
            this._originalDPI = scaledDPI;
            if(this._scaleToDPI)
            {
                if(DeviceCapabilities.isTablet()) //Starling.current.nativeStage))
                {
                    this._originalDPI = ORIGINAL_DPI_IPAD_RETINA;
                }
                else
                {
                    this._originalDPI = ORIGINAL_DPI_IPHONE_RETINA;
                }
            }

            this.scale = scaledDPI / this._originalDPI;

            FeathersControl.defaultTextRendererFactory = textRendererFactory;
            FeathersControl.defaultTextEditorFactory = textEditorFactory;

            const regularFontNames:String = "SourceSansPro";
            const semiboldFontNames:String = "SourceSansProSemibold";

            this.headerTextFormat = new BitmapFontTextFormat(semiboldFontNames, Math.round(36 * this.scale), LIGHT_TEXT_COLOR, true);

            this.smallUIDarkTextFormat = new BitmapFontTextFormat(semiboldFontNames, 24 * this.scale, DARK_TEXT_COLOR, true);
            this.smallUILightTextFormat = new BitmapFontTextFormat(semiboldFontNames, 24 * this.scale, LIGHT_TEXT_COLOR, true);
            this.smallUISelectedTextFormat = new BitmapFontTextFormat(semiboldFontNames, 24 * this.scale, SELECTED_TEXT_COLOR, true);
            this.smallUILightDisabledTextFormat = new BitmapFontTextFormat(semiboldFontNames, 24 * this.scale, DISABLED_TEXT_COLOR, true);
            this.smallUIDarkDisabledTextFormat = new BitmapFontTextFormat(semiboldFontNames, 24 * this.scale, DARK_DISABLED_TEXT_COLOR, true);

            this.largeUIDarkTextFormat = new BitmapFontTextFormat(semiboldFontNames, 28 * this.scale, DARK_TEXT_COLOR, true);
            this.largeUILightTextFormat = new BitmapFontTextFormat(semiboldFontNames, 28 * this.scale, LIGHT_TEXT_COLOR, true);
            this.largeUISelectedTextFormat = new BitmapFontTextFormat(semiboldFontNames, 28 * this.scale, SELECTED_TEXT_COLOR, true);
            this.largeUIDisabledTextFormat = new BitmapFontTextFormat(semiboldFontNames, 28 * this.scale, DISABLED_TEXT_COLOR, true);

            this.smallDarkTextFormat = new BitmapFontTextFormat(regularFontNames, 24 * this.scale, DARK_TEXT_COLOR);
            this.smallLightTextFormat = new BitmapFontTextFormat(regularFontNames, 24 * this.scale, LIGHT_TEXT_COLOR);
            this.smallDisabledTextFormat = new BitmapFontTextFormat(regularFontNames, 24 * this.scale, DISABLED_TEXT_COLOR);
            //this.smallLightTextFormatCentered = new BitmapFontTextFormat(regularFontNames, 24 * this.scale, LIGHT_TEXT_COLOR, null, null, null, null, null, TextFormatAlign.CENTER);
            this.smallLightTextFormatCentered = new BitmapFontTextFormat(regularFontNames, 24 * this.scale, LIGHT_TEXT_COLOR);

            this.largeDarkTextFormat = new BitmapFontTextFormat(regularFontNames, 28 * this.scale, DARK_TEXT_COLOR);
            this.largeLightTextFormat = new BitmapFontTextFormat(regularFontNames, 28 * this.scale, LIGHT_TEXT_COLOR);
            this.largeDisabledTextFormat = new BitmapFontTextFormat(regularFontNames, 28 * this.scale, DISABLED_TEXT_COLOR);

            PopUpManager.overlayFactory = popUpOverlayFactory;
//            Callout.stagePaddingTop = Callout.stagePaddingRight = Callout.stagePaddingBottom =
//                Callout.stagePaddingLeft = 16 * this.scale;

            // Load the theme atlas.
            var xmld = new XMLDocument();
            var res = xmld.loadFile("assets/metalworks.xml");
            Debug.assert(res == 0, "Failed to load skin XML. res="+res);
            this.atlas = new TextureAtlas(Texture.fromAsset("assets/metalworks.png"), xmld.rootElement());

            const backgroundSkinTexture:Texture = this.atlas.getTexture("background-skin");
            const backgroundInsetSkinTexture:Texture = this.atlas.getTexture("background-inset-skin");
            const backgroundDownSkinTexture:Texture = this.atlas.getTexture("background-down-skin");
            const backgroundDisabledSkinTexture:Texture = this.atlas.getTexture("background-disabled-skin");
            const backgroundFocusedSkinTexture:Texture = this.atlas.getTexture("background-focused-skin");
            const backgroundPopUpSkinTexture:Texture = this.atlas.getTexture("background-popup-skin");

            this.backgroundSkinTextures = new Scale9Textures(backgroundSkinTexture, DEFAULT_SCALE9_GRID);
            this.backgroundInsetSkinTextures = new Scale9Textures(backgroundInsetSkinTexture, DEFAULT_SCALE9_GRID);
            this.backgroundDisabledSkinTextures = new Scale9Textures(backgroundDisabledSkinTexture, DEFAULT_SCALE9_GRID);
            this.backgroundFocusedSkinTextures = new Scale9Textures(backgroundFocusedSkinTexture, DEFAULT_SCALE9_GRID);
            this.backgroundPopUpSkinTextures = new Scale9Textures(backgroundPopUpSkinTexture, DEFAULT_SCALE9_GRID);

            this.buttonUpSkinTextures = new Scale9Textures(this.atlas.getTexture("button-up-skin"), BUTTON_SCALE9_GRID);
            this.buttonDownSkinTextures = new Scale9Textures(this.atlas.getTexture("button-down-skin"), BUTTON_SCALE9_GRID);
            this.buttonDisabledSkinTextures = new Scale9Textures(this.atlas.getTexture("button-disabled-skin"), BUTTON_SCALE9_GRID);
            this.buttonSelectedUpSkinTextures = new Scale9Textures(this.atlas.getTexture("button-selected-up-skin"), BUTTON_SELECTED_SCALE9_GRID);
            this.buttonSelectedDisabledSkinTextures = new Scale9Textures(this.atlas.getTexture("button-selected-disabled-skin"), BUTTON_SELECTED_SCALE9_GRID);
            this.buttonCallToActionUpSkinTextures = new Scale9Textures(this.atlas.getTexture("button-call-to-action-up-skin"), BUTTON_SCALE9_GRID);
            this.buttonCallToActionDownSkinTextures = new Scale9Textures(this.atlas.getTexture("button-call-to-action-down-skin"), BUTTON_SCALE9_GRID);
            this.buttonQuietUpSkinTextures = new Scale9Textures(this.atlas.getTexture("button-quiet-up-skin"), BUTTON_SCALE9_GRID);
            this.buttonQuietDownSkinTextures = new Scale9Textures(this.atlas.getTexture("button-quiet-down-skin"), BUTTON_SCALE9_GRID);
            this.buttonDangerUpSkinTextures = new Scale9Textures(this.atlas.getTexture("button-danger-up-skin"), BUTTON_SCALE9_GRID);
            this.buttonDangerDownSkinTextures = new Scale9Textures(this.atlas.getTexture("button-danger-down-skin"), BUTTON_SCALE9_GRID);
            this.buttonBackUpSkinTextures = new Scale3Textures(this.atlas.getTexture("button-back-up-skin"), BACK_BUTTON_SCALE3_REGION1, BACK_BUTTON_SCALE3_REGION2);
            this.buttonBackDownSkinTextures = new Scale3Textures(this.atlas.getTexture("button-back-down-skin"), BACK_BUTTON_SCALE3_REGION1, BACK_BUTTON_SCALE3_REGION2);
            this.buttonBackDisabledSkinTextures = new Scale3Textures(this.atlas.getTexture("button-back-disabled-skin"), BACK_BUTTON_SCALE3_REGION1, BACK_BUTTON_SCALE3_REGION2);
            this.buttonForwardUpSkinTextures = new Scale3Textures(this.atlas.getTexture("button-forward-up-skin"), FORWARD_BUTTON_SCALE3_REGION1, FORWARD_BUTTON_SCALE3_REGION2);
            this.buttonForwardDownSkinTextures = new Scale3Textures(this.atlas.getTexture("button-forward-down-skin"), FORWARD_BUTTON_SCALE3_REGION1, FORWARD_BUTTON_SCALE3_REGION2);
            this.buttonForwardDisabledSkinTextures = new Scale3Textures(this.atlas.getTexture("button-forward-disabled-skin"), FORWARD_BUTTON_SCALE3_REGION1, FORWARD_BUTTON_SCALE3_REGION2);

            this.tabDownSkinTextures = new Scale9Textures(this.atlas.getTexture("tab-down-skin"), TAB_SCALE9_GRID);
            this.tabSelectedSkinTextures = new Scale9Textures(this.atlas.getTexture("tab-selected-skin"), TAB_SCALE9_GRID);
            this.tabSelectedDisabledSkinTextures = new Scale9Textures(this.atlas.getTexture("tab-selected-disabled-skin"), TAB_SCALE9_GRID);

            this.pickerListButtonIconTexture = this.atlas.getTexture("picker-list-icon");
            this.pickerListItemSelectedIconTexture = this.atlas.getTexture("picker-list-item-selected-icon");

            this.radioUpIconTexture = backgroundSkinTexture;
            this.radioDownIconTexture = backgroundDownSkinTexture;
            this.radioDisabledIconTexture = backgroundDisabledSkinTexture;
            this.radioSelectedUpIconTexture = this.atlas.getTexture("radio-selected-up-icon");
            this.radioSelectedDownIconTexture = this.atlas.getTexture("radio-selected-down-icon");
            this.radioSelectedDisabledIconTexture = this.atlas.getTexture("radio-selected-disabled-icon");

            this.checkUpIconTexture = backgroundSkinTexture;
            this.checkDownIconTexture = backgroundDownSkinTexture;
            this.checkDisabledIconTexture = backgroundDisabledSkinTexture;
            this.checkSelectedUpIconTexture = this.atlas.getTexture("check-selected-up-icon");
            this.checkSelectedDownIconTexture = this.atlas.getTexture("check-selected-down-icon");
            this.checkSelectedDisabledIconTexture = this.atlas.getTexture("check-selected-disabled-icon");

            this.pageIndicatorSelectedSkinTexture = this.atlas.getTexture("page-indicator-selected-skin");
            this.pageIndicatorNormalSkinTexture = this.atlas.getTexture("page-indicator-normal-skin");

            this.itemRendererUpSkinTextures = new Scale9Textures(this.atlas.getTexture("list-item-up-skin"), ITEM_RENDERER_SCALE9_GRID);
            this.itemRendererSelectedSkinTextures = new Scale9Textures(this.atlas.getTexture("list-item-selected-skin"), ITEM_RENDERER_SCALE9_GRID);
            this.insetItemRendererFirstUpSkinTextures = new Scale9Textures(this.atlas.getTexture("list-inset-item-first-up-skin"), INSET_ITEM_RENDERER_FIRST_SCALE9_GRID);
            this.insetItemRendererFirstSelectedSkinTextures = new Scale9Textures(this.atlas.getTexture("list-inset-item-first-selected-skin"), INSET_ITEM_RENDERER_FIRST_SCALE9_GRID);
            this.insetItemRendererLastUpSkinTextures = new Scale9Textures(this.atlas.getTexture("list-inset-item-last-up-skin"), INSET_ITEM_RENDERER_LAST_SCALE9_GRID);
            this.insetItemRendererLastSelectedSkinTextures = new Scale9Textures(this.atlas.getTexture("list-inset-item-last-selected-skin"), INSET_ITEM_RENDERER_LAST_SCALE9_GRID);
            this.insetItemRendererSingleUpSkinTextures = new Scale9Textures(this.atlas.getTexture("list-inset-item-single-up-skin"), INSET_ITEM_RENDERER_SINGLE_SCALE9_GRID);
            this.insetItemRendererSingleSelectedSkinTextures = new Scale9Textures(this.atlas.getTexture("list-inset-item-single-selected-skin"), INSET_ITEM_RENDERER_SINGLE_SCALE9_GRID);

            this.headerBackgroundSkinTexture = this.atlas.getTexture("header-background-skin");

            this.calloutTopArrowSkinTexture = this.atlas.getTexture("callout-arrow-top-skin");
            this.calloutRightArrowSkinTexture = this.atlas.getTexture("callout-arrow-right-skin");
            this.calloutBottomArrowSkinTexture = this.atlas.getTexture("callout-arrow-bottom-skin");
            this.calloutLeftArrowSkinTexture = this.atlas.getTexture("callout-arrow-left-skin");

            this.horizontalScrollBarThumbSkinTextures = new Scale3Textures(this.atlas.getTexture("horizontal-scroll-bar-thumb-skin"), SCROLL_BAR_THUMB_REGION1, SCROLL_BAR_THUMB_REGION2, Scale3Textures.DIRECTION_HORIZONTAL);
            this.verticalScrollBarThumbSkinTextures = new Scale3Textures(this.atlas.getTexture("vertical-scroll-bar-thumb-skin"), SCROLL_BAR_THUMB_REGION1, SCROLL_BAR_THUMB_REGION2, Scale3Textures.DIRECTION_VERTICAL);

//            StandardIcons.listDrillDownAccessoryTexture = this.atlas.getTexture("list-accessory-drill-down-icon");

            if(this.root.stage)
            {
                this.initializeRoot();
            }
            else
            {
                this.root.addEventListener(Event.ADDED_TO_STAGE, root_addedToStageHandler);
            }

            this.setInitializerForClassAndSubclasses(Screen, screenInitializer);
            this.setInitializerForClassAndSubclasses(PanelScreen, panelScreenInitializer);
            this.setInitializerForClass(Label, labelInitializer);
//            this.setInitializerForClass(TextFieldTextRenderer, itemRendererAccessoryLabelInitializer, BaseDefaultItemRenderer.DEFAULT_CHILD_NAME_ACCESSORY_LABEL);
//            this.setInitializerForClass(ScrollText, scrollTextInitializer);
            this.setInitializerForClass(Button, buttonInitializer);
            this.setInitializerForClass(Button, callToActionButtonInitializer, Button.ALTERNATE_NAME_CALL_TO_ACTION_BUTTON);
            this.setInitializerForClass(Button, quietButtonInitializer, Button.ALTERNATE_NAME_QUIET_BUTTON);
            this.setInitializerForClass(Button, dangerButtonInitializer, Button.ALTERNATE_NAME_DANGER_BUTTON);
            this.setInitializerForClass(Button, backButtonInitializer, Button.ALTERNATE_NAME_BACK_BUTTON);
            this.setInitializerForClass(Button, forwardButtonInitializer, Button.ALTERNATE_NAME_FORWARD_BUTTON);
            this.setInitializerForClass(Button, buttonInitializer);
//            this.setInitializerForClass(Button, buttonGroupButtonInitializer, ButtonGroup.DEFAULT_CHILD_NAME_BUTTON);
//            this.setInitializerForClass(Button, simpleButtonInitializer, ToggleSwitch.DEFAULT_CHILD_NAME_THUMB);
//            this.setInitializerForClass(Button, simpleButtonInitializer, Slider.DEFAULT_CHILD_NAME_THUMB);
//            this.setInitializerForClass(Button, pickerListButtonInitializer, PickerList.DEFAULT_CHILD_NAME_BUTTON);
            this.setInitializerForClass(Button, tabInitializer, TabBar.DEFAULT_CHILD_NAME_TAB);
//            this.setInitializerForClass(Button, nothingInitializer, Slider.DEFAULT_CHILD_NAME_MINIMUM_TRACK);
//            this.setInitializerForClass(Button, nothingInitializer, Slider.DEFAULT_CHILD_NAME_MAXIMUM_TRACK);
//            this.setInitializerForClass(Button, toggleSwitchTrackInitializer, ToggleSwitch.DEFAULT_CHILD_NAME_ON_TRACK);
            this.setInitializerForClass(Button, nothingInitializer, SimpleScrollBar.DEFAULT_CHILD_NAME_THUMB);
//            this.setInitializerForClass(ButtonGroup, buttonGroupInitializer);
            this.setInitializerForClass(DefaultListItemRenderer, itemRendererInitializer);
            this.setInitializerForClass(DefaultListItemRenderer, pickerListItemRendererInitializer, COMPONENT_NAME_PICKER_LIST_ITEM_RENDERER);
            this.setInitializerForClass(DefaultGroupedListItemRenderer, itemRendererInitializer);
            this.setInitializerForClass(DefaultGroupedListItemRenderer, insetMiddleItemRendererInitializer, GroupedList.ALTERNATE_CHILD_NAME_INSET_ITEM_RENDERER);
            this.setInitializerForClass(DefaultGroupedListItemRenderer, insetFirstItemRendererInitializer, GroupedList.ALTERNATE_CHILD_NAME_INSET_FIRST_ITEM_RENDERER);
            this.setInitializerForClass(DefaultGroupedListItemRenderer, insetLastItemRendererInitializer, GroupedList.ALTERNATE_CHILD_NAME_INSET_LAST_ITEM_RENDERER);
            this.setInitializerForClass(DefaultGroupedListItemRenderer, insetSingleItemRendererInitializer, GroupedList.ALTERNATE_CHILD_NAME_INSET_SINGLE_ITEM_RENDERER);
            this.setInitializerForClass(DefaultGroupedListHeaderOrFooterRenderer, headerRendererInitializer);
            this.setInitializerForClass(DefaultGroupedListHeaderOrFooterRenderer, footerRendererInitializer, GroupedList.DEFAULT_CHILD_NAME_FOOTER_RENDERER);
            this.setInitializerForClass(DefaultGroupedListHeaderOrFooterRenderer, insetHeaderRendererInitializer, GroupedList.ALTERNATE_CHILD_NAME_INSET_HEADER_RENDERER);
            this.setInitializerForClass(DefaultGroupedListHeaderOrFooterRenderer, insetFooterRendererInitializer, GroupedList.ALTERNATE_CHILD_NAME_INSET_FOOTER_RENDERER);
            this.setInitializerForClass(Radio, radioInitializer);
            this.setInitializerForClass(Check, checkInitializer);
//            this.setInitializerForClass(Slider, sliderInitializer);
//            this.setInitializerForClass(ToggleSwitch, toggleSwitchInitializer);
//            this.setInitializerForClass(NumericStepper, numericStepperInitializer);
            this.setInitializerForClass(TextInput, textInputInitializer);
//            this.setInitializerForClass(TextInput, numericStepperTextInputInitializer, NumericStepper.DEFAULT_CHILD_NAME_TEXT_INPUT);
//            this.setInitializerForClass(PageIndicator, pageIndicatorInitializer);
            this.setInitializerForClass(ProgressBar, progressBarInitializer);
//            this.setInitializerForClass(PickerList, pickerListInitializer);
            this.setInitializerForClass(Header, headerInitializer);
            this.setInitializerForClass(Header, headerWithoutBackgroundInitializer, Panel.DEFAULT_CHILD_NAME_HEADER);
//            this.setInitializerForClass(Callout, calloutInitializer);
            this.setInitializerForClass(List, listInitializer);
//            this.setInitializerForClass(List, pickerListListInitializer, PickerList.DEFAULT_CHILD_NAME_LIST);
            this.setInitializerForClass(GroupedList, groupedListInitializer);
            this.setInitializerForClass(GroupedList, insetGroupedListInitializer, GroupedList.ALTERNATE_NAME_INSET_GROUPED_LIST);
            this.setInitializerForClass(Panel, panelInitializer);
            this.setInitializerForClass(ScrollContainer, scrollContainerInitializer);
            this.setInitializerForClass(ScrollContainer, scrollContainerToolbarInitializer, ScrollContainer.ALTERNATE_NAME_TOOLBAR);
        }

        protected function pageIndicatorNormalSymbolFactory():DisplayObject
        {
            const symbol:ImageLoader = new ImageLoader();
            symbol.source = this.pageIndicatorNormalSkinTexture;
            symbol.textureScale = this.scale;
            return symbol;
        }

        protected function pageIndicatorSelectedSymbolFactory():DisplayObject
        {
            const symbol:ImageLoader = new ImageLoader();
            symbol.source = this.pageIndicatorSelectedSkinTexture;
            symbol.textureScale = this.scale;
            return symbol;
        }

        protected function imageLoaderFactory():ImageLoader
        {
            const image:ImageLoader = new ImageLoader();
            image.textureScale = this.scale;
            return image;
        }

        protected function horizontalScrollBarFactory():SimpleScrollBar
        {
            const scrollBar:SimpleScrollBar = new SimpleScrollBar();
            scrollBar.direction = SimpleScrollBar.DIRECTION_HORIZONTAL;
            const defaultSkin:Scale3Image = new Scale3Image(this.horizontalScrollBarThumbSkinTextures, this.scale);
            defaultSkin.width = 10 * this.scale;
            var d:Dictionary.<String, Object> = scrollBar.thumbProperties;
            d["defaultSkin"] = defaultSkin;
            scrollBar.paddingRight = scrollBar.paddingBottom = scrollBar.paddingLeft = 4 * this.scale;
            return scrollBar;
        }

        protected function verticalScrollBarFactory():SimpleScrollBar
        {
            const scrollBar:SimpleScrollBar = new SimpleScrollBar();
            scrollBar.direction = SimpleScrollBar.DIRECTION_VERTICAL;
            const defaultSkin:Scale3Image = new Scale3Image(this.verticalScrollBarThumbSkinTextures, this.scale);
            defaultSkin.height = 10 * this.scale;
            scrollBar.thumbProperties["defaultSkin"] = defaultSkin;
            scrollBar.paddingTop = scrollBar.paddingRight = scrollBar.paddingBottom = 4 * this.scale;
            return scrollBar;
        }

        protected function nothingInitializer(target:DisplayObject):void {}

        protected function screenInitializer(screen:Screen):void
        {
            screen.originalDPI = this._originalDPI;
        } 

        protected function panelScreenInitializer(screen:PanelScreen):void
        {
            screen.originalDPI = this._originalDPI;

            screen.verticalScrollBarFactory = this.verticalScrollBarFactory;
            screen.horizontalScrollBarFactory = this.horizontalScrollBarFactory;
        } 

        protected function simpleButtonInitializer(button:Button):void
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonUpSkinTextures;
            skinSelector.setValueForState(this.buttonDownSkinTextures, Button.STATE_DOWN, false);
            skinSelector.setValueForState(this.buttonDisabledSkinTextures, Button.STATE_DISABLED, false);
            skinSelector.displayObjectProperties =
            {
                width: 60 * this.scale,
                height: 60 * this.scale,
                textureScale: this.scale
            };
            button.stateToSkinFunction = skinSelector.updateValue;

            button.minWidth = button.minHeight = 60 * this.scale;
            button.minTouchWidth = button.minTouchHeight = 88 * this.scale;
        }

        protected function labelInitializer(label:Label):void
        {
            label.textRendererProperties["textFormat"] = this.smallLightTextFormat;
            label.textRendererProperties["embedFonts"] = true;
        }

/*        protected function itemRendererAccessoryLabelInitializer(renderer:TextFieldTextRenderer):void
        {
            renderer.textFormat = this.smallLightTextFormat;
            renderer.embedFonts = true;
        } */

/*        protected function scrollTextInitializer(text:ScrollText):void
        {
            text.textFormat = this.smallLightTextFormat;
            text.embedFonts = true;
            text.paddingTop = text.paddingBottom = text.paddingLeft = 32 * this.scale;
            text.paddingRight = 36 * this.scale;

            text.verticalScrollBarFactory = this.verticalScrollBarFactory;
            text.horizontalScrollBarFactory = this.horizontalScrollBarFactory;
        } */

        protected function baseButtonInitializer(button:Button):void
        {
            button.defaultLabelProperties["textFormat"] = this.smallUIDarkTextFormat;
            button.defaultLabelProperties["embedFonts"] = true;
            button.disabledLabelProperties["textFormat"] = this.smallUIDarkDisabledTextFormat;
            button.disabledLabelProperties["embedFonts"] = true;
            button.selectedDisabledLabelProperties["textFormat"] = this.smallUIDarkDisabledTextFormat;
            button.selectedDisabledLabelProperties["embedFonts"] = true;

            button.paddingTop = button.paddingBottom = 8 * this.scale;
            button.paddingLeft = button.paddingRight = 16 * this.scale;
            button.gap = 12 * this.scale;
            button.minWidth = button.minHeight = 60 * this.scale;
            button.minTouchWidth = button.minTouchHeight = 88 * this.scale;
        }

        protected function buttonInitializer(button:Button):void
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonUpSkinTextures;
            skinSelector.defaultSelectedValue = this.buttonSelectedUpSkinTextures;
            skinSelector.setValueForState(this.buttonDownSkinTextures, Button.STATE_DOWN, false);
            skinSelector.setValueForState(this.buttonDisabledSkinTextures, Button.STATE_DISABLED, false);
            skinSelector.setValueForState(this.buttonSelectedDisabledSkinTextures, Button.STATE_DISABLED, true);
            skinSelector.displayObjectProperties =
            {
                width: 60 * this.scale,
                height: 60 * this.scale,
                textureScale: this.scale
            };
            button.stateToSkinFunction = skinSelector.updateValue;
            this.baseButtonInitializer(button);
        }

        protected function callToActionButtonInitializer(button:Button):void
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonCallToActionUpSkinTextures;
            skinSelector.setValueForState(this.buttonCallToActionDownSkinTextures, Button.STATE_DOWN, false);
            skinSelector.setValueForState(this.buttonDisabledSkinTextures, Button.STATE_DISABLED, false);
            skinSelector.displayObjectProperties =
            {
                width: 60 * this.scale,
                height: 60 * this.scale,
                textureScale: this.scale
            };
            button.stateToSkinFunction = skinSelector.updateValue;
            this.baseButtonInitializer(button);
        }

        protected function quietButtonInitializer(button:Button):void
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonQuietUpSkinTextures;
            skinSelector.setValueForState(this.buttonQuietDownSkinTextures, Button.STATE_DOWN, false);
            skinSelector.setValueForState(this.buttonDisabledSkinTextures, Button.STATE_DISABLED, false);
            skinSelector.displayObjectProperties =
            {
                width: 60 * this.scale,
                height: 60 * this.scale,
                textureScale: this.scale
            };
            button.stateToSkinFunction = skinSelector.updateValue;
            this.baseButtonInitializer(button);
        }

        protected function dangerButtonInitializer(button:Button):void
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonDangerUpSkinTextures;
            skinSelector.setValueForState(this.buttonDangerDownSkinTextures, Button.STATE_DOWN, false);
            skinSelector.setValueForState(this.buttonDisabledSkinTextures, Button.STATE_DISABLED, false);
            skinSelector.displayObjectProperties =
            {
                width: 60 * this.scale,
                height: 60 * this.scale,
                textureScale: this.scale
            };
            button.stateToSkinFunction = skinSelector.updateValue;
            this.baseButtonInitializer(button);
        }

        protected function backButtonInitializer(button:Button):void
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonBackUpSkinTextures;
            skinSelector.setValueForState(this.buttonBackDownSkinTextures, Button.STATE_DOWN, false);
            skinSelector.setValueForState(this.buttonBackDisabledSkinTextures, Button.STATE_DISABLED, false);
            skinSelector.displayObjectProperties =
            {
                width: 60 * this.scale,
                height: 60 * this.scale,
                textureScale: this.scale
            };
            button.stateToSkinFunction = skinSelector.updateValue;
            this.baseButtonInitializer(button);
            button.paddingLeft = 28 * this.scale;
        }

        protected function forwardButtonInitializer(button:Button):void
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonForwardUpSkinTextures;
            skinSelector.setValueForState(this.buttonForwardDownSkinTextures, Button.STATE_DOWN, false);
            skinSelector.setValueForState(this.buttonForwardDisabledSkinTextures, Button.STATE_DISABLED, false);
            skinSelector.displayObjectProperties =
            {
                width: 60 * this.scale,
                height: 60 * this.scale,
                textureScale: this.scale
            };
            button.stateToSkinFunction = skinSelector.updateValue;
            this.baseButtonInitializer(button);
            button.paddingRight = 28 * this.scale;
        }

        protected function buttonGroupButtonInitializer(button:Button):void
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonUpSkinTextures;
            skinSelector.defaultSelectedValue = this.buttonSelectedUpSkinTextures;
            skinSelector.setValueForState(this.buttonDownSkinTextures, Button.STATE_DOWN, false);
            skinSelector.setValueForState(this.buttonDisabledSkinTextures, Button.STATE_DISABLED, false);
            skinSelector.setValueForState(this.buttonSelectedDisabledSkinTextures, Button.STATE_DISABLED, true);
            skinSelector.displayObjectProperties =
            {
                width: 76 * this.scale,
                height: 76 * this.scale,
                textureScale: this.scale
            };
            button.stateToSkinFunction = skinSelector.updateValue;

            button.defaultLabelProperties["textFormat"] = this.largeUIDarkTextFormat;
            button.defaultLabelProperties["embedFonts"] = true;
            button.disabledLabelProperties["textFormat"] = this.largeUIDisabledTextFormat;
            button.disabledLabelProperties["embedFonts"] = true;
            button.selectedDisabledLabelProperties["textFormat"] = this.largeUIDisabledTextFormat;
            button.selectedDisabledLabelProperties["embedFonts"] = true;

            button.paddingTop = button.paddingBottom = 8 * this.scale;
            button.paddingLeft = button.paddingRight = 16 * this.scale;
            button.gap = 12 * this.scale;
            button.minWidth = button.minHeight = 76 * this.scale;
            button.minTouchWidth = button.minTouchHeight = 88 * this.scale;
        }

        protected function pickerListButtonInitializer(button:Button):void
        {
            this.buttonInitializer(button);

            const defaultIcon:ImageLoader = new ImageLoader();
            defaultIcon.source = this.pickerListButtonIconTexture;
            defaultIcon.textureScale = this.scale;
            defaultIcon.snapToPixels = true;
            button.defaultIcon = defaultIcon;

            button.gap = Number.POSITIVE_INFINITY;
            button.iconPosition = Button.ICON_POSITION_RIGHT;
        }

        protected function toggleSwitchTrackInitializer(track:Button):void
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.backgroundSkinTextures;
            skinSelector.setValueForState(this.backgroundDisabledSkinTextures, Button.STATE_DISABLED, false);
            skinSelector.displayObjectProperties =
            {
                width: 140 * this.scale,
                height: 60 * this.scale,
                textureScale: this.scale
            };
            track.stateToSkinFunction = skinSelector.updateValue;
        }

        protected function tabInitializer(tab:Button):void
        {
            const defaultSkin:Quad = new Quad(88 * this.scale, 88 * this.scale, TAB_BACKGROUND_COLOR);
            tab.defaultSkin = defaultSkin;

            const downSkin:Scale9Image = new Scale9Image(this.tabDownSkinTextures, this.scale);
            tab.downSkin = downSkin;

            const defaultSelectedSkin:Scale9Image = new Scale9Image(this.tabSelectedSkinTextures, this.scale);
            tab.defaultSelectedSkin = defaultSelectedSkin;

            const disabledSkin:Quad = new Quad(88 * this.scale, 88 * this.scale, TAB_DISABLED_BACKGROUND_COLOR);
            tab.disabledSkin = disabledSkin;

            const selectedDisabledSkin:Scale9Image = new Scale9Image(this.tabSelectedDisabledSkinTextures, this.scale);
            tab.selectedDisabledSkin = selectedDisabledSkin;

            tab.defaultLabelProperties["textFormat"] = this.smallUILightTextFormat;
            tab.defaultLabelProperties["embedFonts"] = true;
            tab.defaultSelectedLabelProperties["textFormat"] = this.smallUIDarkTextFormat;
            tab.defaultSelectedLabelProperties["embedFonts"] = true;
            tab.disabledLabelProperties["textFormat"] = this.smallUIDarkDisabledTextFormat;
            tab.disabledLabelProperties["embedFonts"] = true;
            tab.selectedDisabledLabelProperties["textFormat"] = this.smallUIDarkDisabledTextFormat;
            tab.selectedDisabledLabelProperties["embedFonts"] = true;

            tab.paddingTop = tab.paddingBottom = 8 * this.scale;
            tab.paddingLeft = tab.paddingRight = 16 * this.scale;
            tab.gap = 12 * this.scale;
            tab.minWidth = tab.minHeight = 88 * this.scale;
            tab.minTouchWidth = tab.minTouchHeight = 88 * this.scale;
        }

/*        protected function buttonGroupInitializer(group:ButtonGroup):void
        {
            group.minWidth = 560 * this.scale;
            group.gap = 18 * this.scale;
        } */

        protected function itemRendererInitializer(renderer:BaseDefaultItemRenderer):void
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.itemRendererUpSkinTextures;
            skinSelector.defaultSelectedValue = this.itemRendererSelectedSkinTextures;
            skinSelector.setValueForState(this.itemRendererSelectedSkinTextures, Button.STATE_DOWN, false);
            skinSelector.displayObjectProperties =
            {
                width: 88 * this.scale,
                height: 88 * this.scale,
                textureScale: this.scale
            };
            renderer.stateToSkinFunction = skinSelector.updateValue;

            renderer.defaultLabelProperties["textFormat"] = this.largeLightTextFormat;
            renderer.defaultLabelProperties["embedFonts"] = true;
            renderer.downLabelProperties["textFormat"] = this.largeDarkTextFormat;
            renderer.downLabelProperties["embedFonts"] = true;
            renderer.defaultSelectedLabelProperties["textFormat"] = this.largeDarkTextFormat;
            renderer.defaultSelectedLabelProperties["embedFonts"] = true;

            renderer.horizontalAlign = Button.HORIZONTAL_ALIGN_LEFT;
            renderer.paddingTop = renderer.paddingBottom = 8 * this.scale;
            renderer.paddingLeft = 32 * this.scale;
            renderer.paddingRight = 24 * this.scale;
            renderer.gap = 20 * this.scale;
            renderer.iconPosition = Button.ICON_POSITION_LEFT;
            renderer.accessoryGap = Number.POSITIVE_INFINITY;
            renderer.accessoryPosition = BaseDefaultItemRenderer.ACCESSORY_POSITION_RIGHT;
            renderer.minWidth = renderer.minHeight = 88 * this.scale;
            renderer.minTouchWidth = renderer.minTouchHeight = 88 * this.scale;

            renderer.accessoryLoaderFactory = this.imageLoaderFactory;
            renderer.iconLoaderFactory = this.imageLoaderFactory;
        }

        protected function pickerListItemRendererInitializer(renderer:BaseDefaultItemRenderer):void
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.itemRendererUpSkinTextures;
            skinSelector.setValueForState(this.itemRendererSelectedSkinTextures, Button.STATE_DOWN, false);
            skinSelector.displayObjectProperties =
            {
                width: 88 * this.scale,
                height: 88 * this.scale,
                textureScale: this.scale
            };
            renderer.stateToSkinFunction = skinSelector.updateValue;

            const defaultSelectedIcon:Image = new Image(this.pickerListItemSelectedIconTexture);
            defaultSelectedIcon.scaleX = defaultSelectedIcon.scaleY = this.scale;
            renderer.defaultSelectedIcon = defaultSelectedIcon;

            const defaultIcon:Quad = new Quad(defaultSelectedIcon.width, defaultSelectedIcon.height, 0xff00ff);
            defaultIcon.alpha = 0;
            renderer.defaultIcon = defaultIcon;

            renderer.defaultLabelProperties["textFormat"] = this.largeLightTextFormat;
            renderer.defaultLabelProperties["embedFonts"] = true;
            renderer.downLabelProperties["textFormat"] = this.largeDarkTextFormat;
            renderer.downLabelProperties["embedFonts"] = true;

            renderer.itemHasIcon = false;
            renderer.horizontalAlign = Button.HORIZONTAL_ALIGN_LEFT;
            renderer.paddingTop = renderer.paddingBottom = 8 * this.scale;
            renderer.paddingLeft = 32 * this.scale;
            renderer.paddingRight = 24 * this.scale;
            renderer.gap = Number.POSITIVE_INFINITY;
            renderer.iconPosition = Button.ICON_POSITION_RIGHT;
            renderer.accessoryGap = Number.POSITIVE_INFINITY;
            renderer.accessoryPosition = BaseDefaultItemRenderer.ACCESSORY_POSITION_RIGHT;
            renderer.minWidth = renderer.minHeight = 88 * this.scale;
            renderer.minTouchWidth = renderer.minTouchHeight = 88 * this.scale;
        }

        protected function insetItemRendererInitializer(renderer:DefaultGroupedListItemRenderer, defaultSkinTextures:Scale9Textures, selectedAndDownSkinTextures:Scale9Textures):void
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = defaultSkinTextures;
            skinSelector.defaultSelectedValue = selectedAndDownSkinTextures;
            skinSelector.setValueForState(selectedAndDownSkinTextures, Button.STATE_DOWN, false);
            skinSelector.displayObjectProperties =
            {
                width: 88 * this.scale,
                height: 88 * this.scale,
                textureScale: this.scale
            };
            renderer.stateToSkinFunction = skinSelector.updateValue;

            renderer.defaultLabelProperties["textFormat"] = this.largeLightTextFormat;
            renderer.defaultLabelProperties["embedFonts"] = true;
            renderer.downLabelProperties["textFormat"] = this.largeDarkTextFormat;
            renderer.downLabelProperties["embedFonts"] = true;
            renderer.defaultSelectedLabelProperties["textFormat"] = this.largeDarkTextFormat;
            renderer.defaultSelectedLabelProperties["embedFonts"] = true;

            renderer.horizontalAlign = Button.HORIZONTAL_ALIGN_LEFT;
            renderer.paddingTop = renderer.paddingBottom = 8 * this.scale;
            renderer.paddingLeft = 32 * this.scale;
            renderer.paddingRight = 24 * this.scale;
            renderer.gap = 20 * this.scale;
            renderer.iconPosition = Button.ICON_POSITION_LEFT;
            renderer.accessoryGap = Number.POSITIVE_INFINITY;
            renderer.accessoryPosition = BaseDefaultItemRenderer.ACCESSORY_POSITION_RIGHT;
            renderer.minWidth = renderer.minHeight = 88 * this.scale;
            renderer.minTouchWidth = renderer.minTouchHeight = 88 * this.scale;

            renderer.accessoryLoaderFactory = this.imageLoaderFactory;
            renderer.iconLoaderFactory = this.imageLoaderFactory;
        }

        protected function insetMiddleItemRendererInitializer(renderer:DefaultGroupedListItemRenderer):void
        {
            this.insetItemRendererInitializer(renderer, this.itemRendererUpSkinTextures, this.itemRendererSelectedSkinTextures);
        }

        protected function insetFirstItemRendererInitializer(renderer:DefaultGroupedListItemRenderer):void
        {
            this.insetItemRendererInitializer(renderer, this.insetItemRendererFirstUpSkinTextures, this.insetItemRendererFirstSelectedSkinTextures);
        }

        protected function insetLastItemRendererInitializer(renderer:DefaultGroupedListItemRenderer):void
        {
            this.insetItemRendererInitializer(renderer, this.insetItemRendererLastUpSkinTextures, this.insetItemRendererLastSelectedSkinTextures);
        }

        protected function insetSingleItemRendererInitializer(renderer:DefaultGroupedListItemRenderer):void
        {
            this.insetItemRendererInitializer(renderer, this.insetItemRendererSingleUpSkinTextures, this.insetItemRendererSingleSelectedSkinTextures);
        }

        protected function headerRendererInitializer(renderer:DefaultGroupedListHeaderOrFooterRenderer):void
        {
            const defaultSkin:Quad = new Quad(44 * this.scale, 44 * this.scale, GROUPED_LIST_HEADER_BACKGROUND_COLOR);
            renderer.backgroundSkin = defaultSkin;

            renderer.horizontalAlign = DefaultGroupedListHeaderOrFooterRenderer.HORIZONTAL_ALIGN_LEFT;
            renderer.contentLabelProperties["textFormat"] = this.smallUILightTextFormat;
            renderer.contentLabelProperties["embedFonts"] = true;
            renderer.paddingTop = renderer.paddingBottom = 4 * this.scale;
            renderer.paddingLeft = renderer.paddingRight = 16 * this.scale;
            renderer.minWidth = renderer.minHeight = 44 * this.scale;
            renderer.minTouchWidth = renderer.minTouchHeight = 44 * this.scale;

            renderer.contentLoaderFactory = this.imageLoaderFactory;
        }

        protected function footerRendererInitializer(renderer:DefaultGroupedListHeaderOrFooterRenderer):void
        {
            const defaultSkin:Quad = new Quad(44 * this.scale, 44 * this.scale, GROUPED_LIST_FOOTER_BACKGROUND_COLOR);
            renderer.backgroundSkin = defaultSkin;

            renderer.horizontalAlign = DefaultGroupedListHeaderOrFooterRenderer.HORIZONTAL_ALIGN_CENTER;
            renderer.contentLabelProperties["textFormat"] = this.smallLightTextFormat;
            renderer.contentLabelProperties["embedFonts"] = true;
            renderer.paddingTop = renderer.paddingBottom = 4 * this.scale;
            renderer.paddingLeft = renderer.paddingRight = 16 * this.scale;
            renderer.minWidth = renderer.minHeight = 44 * this.scale;
            renderer.minTouchWidth = renderer.minTouchHeight = 44 * this.scale;

            renderer.contentLoaderFactory = this.imageLoaderFactory;
        }

        protected function insetHeaderRendererInitializer(renderer:DefaultGroupedListHeaderOrFooterRenderer):void
        {
            const defaultSkin:Quad = new Quad(66 * this.scale, 66 * this.scale, 0xff00ff);
            defaultSkin.alpha = 0;
            renderer.backgroundSkin = defaultSkin;

            renderer.horizontalAlign = DefaultGroupedListHeaderOrFooterRenderer.HORIZONTAL_ALIGN_LEFT;
            renderer.contentLabelProperties["textFormat"] = this.smallUILightTextFormat;
            renderer.contentLabelProperties["embedFonts"] = true;
            renderer.paddingTop = renderer.paddingBottom = 4 * this.scale;
            renderer.paddingLeft = renderer.paddingRight = 32 * this.scale;
            renderer.minWidth = renderer.minHeight = 66 * this.scale;
            renderer.minTouchWidth = renderer.minTouchHeight = 44 * this.scale;

            renderer.contentLoaderFactory = this.imageLoaderFactory;
        }

        protected function insetFooterRendererInitializer(renderer:DefaultGroupedListHeaderOrFooterRenderer):void
        {
            const defaultSkin:Quad = new Quad(66 * this.scale, 66 * this.scale, 0xff00ff);
            defaultSkin.alpha = 0;
            renderer.backgroundSkin = defaultSkin;

            renderer.horizontalAlign = DefaultGroupedListHeaderOrFooterRenderer.HORIZONTAL_ALIGN_CENTER;
            renderer.contentLabelProperties["textFormat"] = this.smallLightTextFormat;
            renderer.contentLabelProperties["embedFonts"] = true;
            renderer.paddingTop = renderer.paddingBottom = 4 * this.scale;
            renderer.paddingLeft = renderer.paddingRight = 32 * this.scale;
            renderer.minWidth = renderer.minHeight = 66 * this.scale;
            renderer.minTouchWidth = renderer.minTouchHeight = 44 * this.scale;

            renderer.contentLoaderFactory = this.imageLoaderFactory;
        }

        protected function radioInitializer(radio:Radio):void
        {
            const iconSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            iconSelector.defaultValue = this.radioUpIconTexture;
            iconSelector.defaultSelectedValue = this.radioSelectedUpIconTexture;
            iconSelector.setValueForState(this.radioDownIconTexture, Button.STATE_DOWN, false);
            iconSelector.setValueForState(this.radioDisabledIconTexture, Button.STATE_DISABLED, false);
            iconSelector.setValueForState(this.radioSelectedDownIconTexture, Button.STATE_DOWN, true);
            iconSelector.setValueForState(this.radioSelectedDisabledIconTexture, Button.STATE_DISABLED, true);
            iconSelector.displayObjectProperties =
            {
                scaleX: this.scale,
                scaleY: this.scale
            };
            radio.stateToIconFunction = iconSelector.updateValue;

            radio.defaultLabelProperties["textFormat"] = this.smallUILightTextFormat;
            radio.defaultLabelProperties["embedFonts"] = true;
            radio.disabledLabelProperties["textFormat"] = this.smallUILightDisabledTextFormat;
            radio.disabledLabelProperties["embedFonts"] = true;
            radio.selectedDisabledLabelProperties["textFormat"] = this.smallUILightDisabledTextFormat;
            radio.selectedDisabledLabelProperties["embedFonts"] = true;

            radio.gap = 8 * this.scale;
            radio.minTouchWidth = radio.minTouchHeight = 88 * this.scale;
        }

        protected function checkInitializer(check:Check):void
        {
            const iconSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            iconSelector.defaultValue = this.checkUpIconTexture;
            iconSelector.defaultSelectedValue = this.checkSelectedUpIconTexture;
            iconSelector.setValueForState(this.checkDownIconTexture, Button.STATE_DOWN, false);
            iconSelector.setValueForState(this.checkDisabledIconTexture, Button.STATE_DISABLED, false);
            iconSelector.setValueForState(this.checkSelectedDownIconTexture, Button.STATE_DOWN, true);
            iconSelector.setValueForState(this.checkSelectedDisabledIconTexture, Button.STATE_DISABLED, true);
            iconSelector.displayObjectProperties =
            {
                scaleX: this.scale,
                scaleY: this.scale
            };
            check.stateToIconFunction = iconSelector.updateValue;

            check.defaultLabelProperties["textFormat"] = this.smallUILightTextFormat;
            check.defaultLabelProperties["embedFonts"] = true;
            check.disabledLabelProperties["textFormat"] = this.smallUILightDisabledTextFormat;
            check.disabledLabelProperties["embedFonts"] = true;
            check.selectedDisabledLabelProperties["textFormat"] = this.smallUILightDisabledTextFormat;
            check.selectedDisabledLabelProperties["embedFonts"] = true;

            check.gap = 8 * this.scale;
            check.minTouchWidth = check.minTouchHeight = 88 * this.scale;
        }

/*        protected function sliderInitializer(slider:Slider):void
        {
            slider.trackLayoutMode = Slider.TRACK_LAYOUT_MODE_MIN_MAX;

            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.backgroundSkinTextures;
            skinSelector.setValueForState(this.buttonDownSkinTextures, Button.STATE_DOWN, false);
            skinSelector.setValueForState(this.backgroundDisabledSkinTextures, Button.STATE_DISABLED, false);
            skinSelector.displayObjectProperties =
            {
                textureScale: this.scale
            };
            if(slider.direction == Slider.DIRECTION_VERTICAL)
            {
                skinSelector.displayObjectProperties["width"] = 60 * this.scale;
                skinSelector.displayObjectProperties["height"] = 210 * this.scale;
            }
            else
            {
                skinSelector.displayObjectProperties["width"] = 210 * this.scale;
                skinSelector.displayObjectProperties["height"] = 60 * this.scale;
            }
            slider.minimumTrackProperties["stateToSkinFunction"] = skinSelector.updateValue;
            slider.maximumTrackProperties["stateToSkinFunction"] = skinSelector.updateValue;
        } */

/*        protected function toggleSwitchInitializer(toggle:ToggleSwitch):void
        {
            toggle.trackLayoutMode = ToggleSwitch.TRACK_LAYOUT_MODE_SINGLE;

            toggle.defaultLabelProperties["textFormat"] = this.smallUILightTextFormat;
            toggle.defaultLabelProperties["embedFonts"] = true;
            toggle.onLabelProperties["textFormat"] = this.smallUISelectedTextFormat;
            toggle.onLabelProperties["embedFonts"] = true;
        } */

/*        protected function numericStepperInitializer(stepper:NumericStepper):void
        {
            stepper.buttonLayoutMode = NumericStepper.BUTTON_LAYOUT_MODE_SPLIT_HORIZONTAL;
            stepper.incrementButtonLabel = "+";
            stepper.decrementButtonLabel = "-";
        } */

        protected function textInputInitializer(input:TextInput):void
        {
            const backgroundSkin:Scale9Image = new Scale9Image(this.backgroundInsetSkinTextures, this.scale);
            backgroundSkin.width = 264 * this.scale;
            backgroundSkin.height = 60 * this.scale;
            input.backgroundSkin = backgroundSkin;

            const backgroundDisabledSkin:Scale9Image = new Scale9Image(this.backgroundDisabledSkinTextures, this.scale);
            backgroundDisabledSkin.width = 264 * this.scale;
            backgroundDisabledSkin.height = 60 * this.scale;
            input.backgroundDisabledSkin = backgroundDisabledSkin;

            const backgroundFocusedSkin:Scale9Image = new Scale9Image(this.backgroundFocusedSkinTextures, this.scale);
            backgroundFocusedSkin.width = 264 * this.scale;
            backgroundFocusedSkin.height = 60 * this.scale;
            input.backgroundFocusedSkin = backgroundFocusedSkin;

            input.minWidth = input.minHeight = 60 * this.scale;
            input.minTouchWidth = input.minTouchHeight = 88 * this.scale;
            input.paddingTop = 12 * this.scale;
            input.paddingBottom = 10 * this.scale;
            input.paddingLeft = input.paddingRight = 14 * this.scale;
            input.textEditorProperties["textFormat"] = this.smallLightTextFormat;

            input.promptProperties["textFormat"] = this.smallLightTextFormat;
            input.promptProperties["embedFonts"] = true;
        } 

/*        protected function numericStepperTextInputInitializer(input:TextInput):void
        {
            const backgroundSkin:Scale9Image = new Scale9Image(this.backgroundSkinTextures, this.scale);
            backgroundSkin.width = 60 * this.scale;
            backgroundSkin.height = 60 * this.scale;
            input.backgroundSkin = backgroundSkin;

            const backgroundDisabledSkin:Scale9Image = new Scale9Image(this.backgroundDisabledSkinTextures, this.scale);
            backgroundDisabledSkin.width = 60 * this.scale;
            backgroundDisabledSkin.height = 60 * this.scale;
            input.backgroundDisabledSkin = backgroundDisabledSkin;

            const backgroundFocusedSkin:Scale9Image = new Scale9Image(this.backgroundFocusedSkinTextures, this.scale);
            backgroundFocusedSkin.width = 60 * this.scale;
            backgroundFocusedSkin.height = 60 * this.scale;
            input.backgroundFocusedSkin = backgroundFocusedSkin;

            input.minWidth = input.minHeight = 60 * this.scale;
            input.minTouchWidth = input.minTouchHeight = 88 * this.scale;
            input.paddingTop = 12 * this.scale;
            input.paddingBottom = 10 * this.scale;
            input.paddingLeft = input.paddingRight = 14 * this.scale;
            input.isEditable = false;
            input.textEditorFactory = stepperTextEditorFactory;
            input.textEditorProperties["textFormat"] = this.smallLightTextFormatCentered;
            input.textEditorProperties["embedFonts"] = true;
        } */

/*        protected function pageIndicatorInitializer(pageIndicator:PageIndicator):void
        {
            pageIndicator.normalSymbolFactory = this.pageIndicatorNormalSymbolFactory;
            pageIndicator.selectedSymbolFactory = this.pageIndicatorSelectedSymbolFactory;
            pageIndicator.gap = 10 * this.scale;
            pageIndicator.paddingTop = pageIndicator.paddingRight = pageIndicator.paddingBottom =
                pageIndicator.paddingLeft = 6 * this.scale;
            pageIndicator.minTouchWidth = pageIndicator.minTouchHeight = 44 * this.scale;
        } */

        protected function progressBarInitializer(progress:ProgressBar):void
        {
            const backgroundSkin:Scale9Image = new Scale9Image(this.backgroundSkinTextures, this.scale);
            backgroundSkin.width = 240 * this.scale;
            backgroundSkin.height = 22 * this.scale;
            progress.backgroundSkin = backgroundSkin;

            const backgroundDisabledSkin:Scale9Image = new Scale9Image(this.backgroundDisabledSkinTextures, this.scale);
            backgroundDisabledSkin.width = 240 * this.scale;
            backgroundDisabledSkin.height = 22 * this.scale;
            progress.backgroundDisabledSkin = backgroundDisabledSkin;

            const fillSkin:Scale9Image = new Scale9Image(this.buttonUpSkinTextures, this.scale);
            fillSkin.width = 8 * this.scale;
            fillSkin.height = 22 * this.scale;
            progress.fillSkin = fillSkin;

            const fillDisabledSkin:Scale9Image = new Scale9Image(this.buttonDisabledSkinTextures, this.scale);
            fillDisabledSkin.width = 8 * this.scale;
            fillDisabledSkin.height = 22 * this.scale;
            progress.fillDisabledSkin = fillDisabledSkin;
        } 

        protected function headerInitializer(header:Header):void
        {
            header.minWidth = 88 * this.scale;
            header.minHeight = 88 * this.scale;
            header.paddingTop = header.paddingRight = header.paddingBottom =
                header.paddingLeft = 14 * this.scale;
            header.gap = 8 * this.scale;
            header.titleGap = 12 * this.scale;

            const backgroundSkin:TiledImage = new TiledImage(this.headerBackgroundSkinTexture, this.scale);
            backgroundSkin.width = backgroundSkin.height = 88 * this.scale;
            header.backgroundSkin = backgroundSkin;
            header.titleProperties["textFormat"] = this.headerTextFormat;
            header.titleProperties["embedFonts"] = true;
        }

        protected function headerWithoutBackgroundInitializer(header:Header):void
        {
            header.minWidth = 88 * this.scale;
            header.minHeight = 88 * this.scale;
            header.paddingTop = header.paddingBottom = 14 * this.scale;
            header.paddingLeft = header.paddingRight = 18 * this.scale;

            header.titleProperties["textFormat"] = this.headerTextFormat;
            header.titleProperties["embedFonts"] = true;
        }

/*        protected function pickerListInitializer(list:PickerList):void
        {
            if(DeviceCapabilities.isTablet(Starling.current.nativeStage))
            {
                list.popUpContentManager = new CalloutPopUpContentManager();
            }
            else
            {
                const centerStage:VerticalCenteredPopUpContentManager = new VerticalCenteredPopUpContentManager();
                centerStage.marginTop = centerStage.marginRight = centerStage.marginBottom =
                    centerStage.marginLeft = 24 * this.scale;
                list.popUpContentManager = centerStage;
            }

            const layout:VerticalLayout = new VerticalLayout();
            layout.verticalAlign = VerticalLayout.VERTICAL_ALIGN_BOTTOM;
            layout.horizontalAlign = VerticalLayout.HORIZONTAL_ALIGN_JUSTIFY;
            layout.useVirtualLayout = true;
            layout.gap = 0;
            layout.paddingTop = layout.paddingRight = layout.paddingBottom =
                layout.paddingLeft = 0;
            list.listProperties["layout"] = layout;
            list.listProperties["verticalScrollPolicy"] = List.SCROLL_POLICY_ON;
            list.listProperties["verticalScrollBarFactory"] = this.verticalScrollBarFactory;
            list.listProperties["horizontalScrollBarFactory"] = this.horizontalScrollBarFactory;

            if(DeviceCapabilities.isTablet(Starling.current.nativeStage))
            {
                list.listProperties["minWidth"] = 560 * this.scale;
                list.listProperties["maxHeight"] = 528 * this.scale;
            }
            else
            {
                const backgroundSkin:Scale9Image = new Scale9Image(this.backgroundSkinTextures, this.scale);
                backgroundSkin.width = 20 * this.scale;
                backgroundSkin.height = 20 * this.scale;
                list.listProperties["backgroundSkin"] = backgroundSkin;
                list.listProperties["paddingTop"] = list.listProperties["paddingRight"] =
                    list.listProperties["paddingBottom"] = list.listProperties["paddingLeft"] = 8 * this.scale;
            }

            list.listProperties["itemRendererName"] = COMPONENT_NAME_PICKER_LIST_ITEM_RENDERER;
        } */

/*        protected function calloutInitializer(callout:Callout):void
        {
            const backgroundSkin:Scale9Image = new Scale9Image(this.backgroundPopUpSkinTextures, this.scale);
            callout.backgroundSkin = backgroundSkin;

            const topArrowSkin:Image = new Image(this.calloutTopArrowSkinTexture);
            topArrowSkin.scaleX = topArrowSkin.scaleY = this.scale;
            callout.topArrowSkin = topArrowSkin;

            const rightArrowSkin:Image = new Image(this.calloutRightArrowSkinTexture);
            rightArrowSkin.scaleX = rightArrowSkin.scaleY = this.scale;
            callout.rightArrowSkin = rightArrowSkin;

            const bottomArrowSkin:Image = new Image(this.calloutBottomArrowSkinTexture);
            bottomArrowSkin.scaleX = bottomArrowSkin.scaleY = this.scale;
            callout.bottomArrowSkin = bottomArrowSkin;

            const leftArrowSkin:Image = new Image(this.calloutLeftArrowSkinTexture);
            leftArrowSkin.scaleX = leftArrowSkin.scaleY = this.scale;
            callout.leftArrowSkin = leftArrowSkin;

            callout.padding = 8 * this.scale;
        } */

        protected function panelInitializer(panel:Panel):void
        {
            const backgroundSkin:Scale9Image = new Scale9Image(this.backgroundPopUpSkinTextures, this.scale);
            panel.backgroundSkin = backgroundSkin;

            panel.paddingTop = 0;
            panel.paddingRight = 8 * this.scale;
            panel.paddingBottom = 8 * this.scale;
            panel.paddingLeft = 8 * this.scale;

            panel.verticalScrollBarFactory = this.verticalScrollBarFactory;
            panel.horizontalScrollBarFactory = this.horizontalScrollBarFactory;
        }

        protected function listInitializer(list:List):void
        {
            const backgroundSkin:Quad = new Quad(100, 100, LIST_BACKGROUND_COLOR);
            list.backgroundSkin = backgroundSkin;

            list.verticalScrollBarFactory = this.verticalScrollBarFactory;
            list.horizontalScrollBarFactory = this.horizontalScrollBarFactory;
        }

        protected function pickerListListInitializer(list:List):void
        {
            list.verticalScrollBarFactory = this.verticalScrollBarFactory;
            list.horizontalScrollBarFactory = this.horizontalScrollBarFactory;
        }

        protected function groupedListInitializer(list:GroupedList):void
        {
            const backgroundSkin:Quad = new Quad(100, 100, LIST_BACKGROUND_COLOR);
            list.backgroundSkin = backgroundSkin;

            list.verticalScrollBarFactory = this.verticalScrollBarFactory;
            list.horizontalScrollBarFactory = this.horizontalScrollBarFactory;
        }

        protected function scrollContainerInitializer(container:ScrollContainer):void
        {
            container.verticalScrollBarFactory = this.verticalScrollBarFactory;
            container.horizontalScrollBarFactory = this.horizontalScrollBarFactory;
        }

        protected function scrollContainerToolbarInitializer(container:ScrollContainer):void
        {
            const layout:HorizontalLayout = new HorizontalLayout();
            layout.paddingTop = layout.paddingRight = layout.paddingBottom =
                layout.paddingLeft = 14 * this.scale;
            layout.gap = 8 * this.scale;
            container.layout = layout;
            container.minWidth = 88 * this.scale;
            container.minHeight = 88 * this.scale;

            const backgroundSkin:TiledImage = new TiledImage(this.headerBackgroundSkinTexture, this.scale);
            backgroundSkin.width = backgroundSkin.height = 88 * this.scale;
            container.backgroundSkin = backgroundSkin;

            container.verticalScrollBarFactory = this.verticalScrollBarFactory;
            container.horizontalScrollBarFactory = this.horizontalScrollBarFactory;
        }

        protected function insetGroupedListInitializer(list:GroupedList):void
        {
            list.itemRendererName = GroupedList.ALTERNATE_CHILD_NAME_INSET_ITEM_RENDERER;
            list.firstItemRendererName = GroupedList.ALTERNATE_CHILD_NAME_INSET_FIRST_ITEM_RENDERER;
            list.lastItemRendererName = GroupedList.ALTERNATE_CHILD_NAME_INSET_LAST_ITEM_RENDERER;
            list.singleItemRendererName = GroupedList.ALTERNATE_CHILD_NAME_INSET_SINGLE_ITEM_RENDERER;
            list.headerRendererName = GroupedList.ALTERNATE_CHILD_NAME_INSET_HEADER_RENDERER;
            list.footerRendererName = GroupedList.ALTERNATE_CHILD_NAME_INSET_FOOTER_RENDERER;

            const layout:VerticalLayout = new VerticalLayout();
            layout.useVirtualLayout = true;
            layout.padding = 18 * this.scale;
            layout.gap = 0;
            layout.horizontalAlign = VerticalLayout.HORIZONTAL_ALIGN_JUSTIFY;
            layout.verticalAlign = VerticalLayout.VERTICAL_ALIGN_TOP;
            layout.manageVisibility = true;
            list.layout = layout;

            list.verticalScrollBarFactory = this.verticalScrollBarFactory;
            list.horizontalScrollBarFactory = this.horizontalScrollBarFactory;
        }

        protected function root_addedToStageHandler(event:Event):void
        {
            this.initializeRoot();
        }

    }
}
