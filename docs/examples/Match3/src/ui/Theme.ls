package ui {
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.core.DisplayListWatcher;
	import feathers.skins.SmartDisplayObjectStateValueSelector;
	import feathers.text.BitmapFontTextFormat;
	import feathers.textures.Scale9Textures;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.Loom2D;
	import loom2d.math.Rectangle;
	import loom2d.textures.Texture;
	
	public class Theme extends DisplayListWatcher {
		
		public const DEFAULT_SCALE9_GRID:Rectangle = new Rectangle(5, 5, 10, 10);
		//public const BUTTON_SCALE9_GRID:Rectangle = new Rectangle(5, 5, 50, 10);
		
		public var textFormat:BitmapFontTextFormat;
		public var textFormatDisabled:BitmapFontTextFormat;
		
		public var buttonUp:Scale9Textures;
		public var buttonDown:Scale9Textures;
		public var checkUpIcon:Scale9Textures;
		public var checkDownIcon:Scale9Textures;
		public var checkSelectedUpIcon:Scale9Textures;
		public var checkSelectedDownIcon:Scale9Textures;
		
		public function Theme(container:DisplayObjectContainer = null)
        {
            if(!container)
            {
                container = Loom2D.stage;
            }
            super(container);
            this.initialize();
        }
		
		protected function initialize() {
			
			var scale = 4;
			
			textFormat = new BitmapFontTextFormat("SourceSansPro", 8*scale, 0x000000);
			//textFormat = new BitmapFontTextFormat("SourceSansPro", 8*scale, 0xFFFFFF);
			
			const background = Texture.fromAsset("assets/ui/background-skin.png");
			const backgroundDown = Texture.fromAsset("assets/ui/background-down-skin.png");
			const background9 = new Scale9Textures(background, DEFAULT_SCALE9_GRID);
			const backgroundDown9 = new Scale9Textures(backgroundDown, DEFAULT_SCALE9_GRID);
			
			buttonUp = background9;
			buttonDown = backgroundDown9;
			checkUpIcon = background9;
			checkDownIcon = backgroundDown9;
			checkSelectedUpIcon = new Scale9Textures(Texture.fromAsset("assets/ui/check-selected-up-icon.png"), DEFAULT_SCALE9_GRID);
			checkSelectedDownIcon = new Scale9Textures(Texture.fromAsset("assets/ui/check-selected-down-icon.png"), DEFAULT_SCALE9_GRID);
			
			setInitializerForClass(Label, labelInitializer);
			setInitializerForClass(Button, buttonInitializer);
			setInitializerForClass(Check, checkInitializer);
		}
		
		protected function labelInitializer(label:Label) {
			label.textRendererProperties["textFormat"] = textFormat;
			label.textRendererProperties["embedFonts"] = true;
		}
		
		protected function baseButtonInitializer(button:Button):void
        {
            //button.defaultLabelProperties["textFormat"] = this.smallUIDarkTextFormat;
            button.defaultLabelProperties["textFormat"] = textFormat;
            button.defaultLabelProperties["embedFonts"] = true;
            //button.disabledLabelProperties["textFormat"] = this.smallUIDarkDisabledTextFormat;
            //button.disabledLabelProperties["embedFonts"] = true;
            //button.selectedDisabledLabelProperties["textFormat"] = this.smallUIDarkDisabledTextFormat;
            //button.selectedDisabledLabelProperties["embedFonts"] = true;

            //button.paddingTop = button.paddingBottom = 8 * this.scale;
            //button.paddingLeft = button.paddingRight = 16 * this.scale;
            //button.gap = 12 * this.scale;
            //button.minWidth = button.minHeight = 60 * this.scale;
            //button.minTouchWidth = button.minTouchHeight = 88 * this.scale;
        }
		
		protected function buttonInitializer(button:Button):void
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonUp;
            //skinSelector.defaultSelectedValue = this.buttonDownSkinTextures;
            skinSelector.setValueForState(this.buttonDown, Button.STATE_DOWN, false);
            //skinSelector.setValueForState(this.buttonDisabledSkinTextures, Button.STATE_DISABLED, false);
            //skinSelector.setValueForState(this.buttonSelectedDisabledSkinTextures, Button.STATE_DISABLED, true);
            skinSelector.displayObjectProperties =
            {
                width: 60,
                height: 20,
                textureScale: 1
            };
            button.stateToSkinFunction = skinSelector.updateValue;
            this.baseButtonInitializer(button);
        }
		
		protected function checkInitializer(check:Check):void
        {
            const iconSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            iconSelector.defaultValue = this.checkUpIcon;
            iconSelector.defaultSelectedValue = this.checkSelectedUpIcon;
            iconSelector.setValueForState(this.checkDownIcon, Button.STATE_DOWN, false);
            //iconSelector.setValueForState(this.checkDisabledIconTexture, Button.STATE_DISABLED, false);
            iconSelector.setValueForState(this.checkSelectedDownIcon, Button.STATE_DOWN, true);
            //iconSelector.setValueForState(this.checkSelectedDisabledIconTexture, Button.STATE_DISABLED, true);
            //iconSelector.displayObjectProperties =
            //{
                //scaleX: this.scale,
                //scaleY: this.scale
            //};
            check.stateToIconFunction = iconSelector.updateValue;
			
			const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonUp;
            //skinSelector.defaultSelectedValue = this.buttonDownSkinTextures;
            skinSelector.setValueForState(this.buttonDown, Button.STATE_DOWN, false);
            //skinSelector.setValueForState(this.buttonDisabledSkinTextures, Button.STATE_DISABLED, false);
            //skinSelector.setValueForState(this.buttonSelectedDisabledSkinTextures, Button.STATE_DISABLED, true);
            //skinSelector.displayObjectProperties =
            //{
                //width: 60 * this.scale,
                //height: 60 * this.scale,
                //textureScale: this.scale
            //};
            check.stateToSkinFunction = skinSelector.updateValue;
			
            check.defaultLabelProperties["textFormat"] = this.textFormat;
            check.defaultLabelProperties["embedFonts"] = true;
            //check.disabledLabelProperties["textFormat"] = this.smallUILightDisabledTextFormat;
            //check.disabledLabelProperties["embedFonts"] = true;
            //check.selectedDisabledLabelProperties["textFormat"] = this.smallUILightDisabledTextFormat;
            //check.selectedDisabledLabelProperties["embedFonts"] = true;
			
            check.gap = 2;
			check.padding = 2;
            //check.minTouchWidth = check.minTouchHeight = 88 * this.scale;
        }
		
	}
	
}