package ui {
	import feathers.controls.Button;
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.core.DisplayListWatcher;
	import feathers.skins.SmartDisplayObjectStateValueSelector;
	import feathers.text.BitmapFontTextFormat;
	import feathers.text.TextFormatAlign;
	import feathers.textures.Scale9Textures;
	import loom2d.display.DisplayObjectContainer;
	import loom2d.Loom2D;
	import loom2d.math.Rectangle;
	import loom2d.text.BitmapFont;
	import loom2d.text.TextField;
	import loom2d.textures.Texture;
	
	public class Theme extends DisplayListWatcher
	{
		public const DEFAULT_SCALE9_GRID:Rectangle = new Rectangle(5, 5, 10, 10);
		
		public var textFormat:BitmapFontTextFormat;
		public var textFormatDisabled:BitmapFontTextFormat;
		public var textFormatLight:BitmapFontTextFormat;
		public var textFormatTitle:BitmapFontTextFormat;
		public var textFormatHeader:BitmapFontTextFormat;
		
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
		
		protected function initialize()
		{
			TextField.registerBitmapFont(BitmapFont.load("assets/kremlin-export.fnt"), "SourceSansPro");
			TextField.registerBitmapFont(BitmapFont.load("assets/kremlin-export.fnt"), "main");
			
			var scale = 4;
			
			textFormat = new BitmapFontTextFormat("main", 8*scale, 0x000000);
			textFormatLight = new BitmapFontTextFormat("main", 8*scale, 0xFFFFFF);
			textFormatTitle = new BitmapFontTextFormat("main", 4*8*scale, 0xFFFFFF, false, TextFormatAlign.CENTER);
			textFormatHeader = new BitmapFontTextFormat("main", 2*8*scale, 0xFFFFFF, false, TextFormatAlign.CENTER);
			
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
			setInitializerForClass(Label, labelInitializerLight, "light");
			setInitializerForClass(Label, labelInitializerTitle, "title");
			setInitializerForClass(Label, labelInitializerHeader, "header");
			setInitializerForClass(Button, buttonInitializer);
			setInitializerForClass(Check, checkInitializer);
		}
		
		protected function labelInitializer(label:Label)
		{
			label.textRendererProperties["textFormat"] = textFormat;
			label.textRendererProperties["embedFonts"] = true;
		}
		
		protected function labelInitializerLight(label:Label)
		{
			labelInitializer(label);
			label.textRendererProperties["textFormat"] = textFormatLight;
		}
		
		protected function labelInitializerTitle(label:Label)
		{
			labelInitializer(label);
			label.textRendererProperties["textFormat"] = textFormatTitle;
		}
		
		protected function labelInitializerHeader(label:Label)
		{
			labelInitializer(label);
			label.textRendererProperties["textFormat"] = textFormatHeader;
		}
		
		protected function baseButtonInitializer(button:Button)
        {
            button.defaultLabelProperties["textFormat"] = textFormat;
            button.defaultLabelProperties["embedFonts"] = true;
        }
		
		protected function buttonInitializer(button:Button)
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonUp;
            skinSelector.setValueForState(this.buttonDown, Button.STATE_DOWN, false);
            skinSelector.displayObjectProperties =
            {
                width: 60,
                height: 20,
                textureScale: 1
            };
            button.stateToSkinFunction = skinSelector.updateValue;
            this.baseButtonInitializer(button);
        }
		
		protected function checkInitializer(check:Check)
        {
            const iconSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            iconSelector.defaultValue = this.checkUpIcon;
            iconSelector.defaultSelectedValue = this.checkSelectedUpIcon;
            iconSelector.setValueForState(this.checkDownIcon, Button.STATE_DOWN, false);
            iconSelector.setValueForState(this.checkSelectedDownIcon, Button.STATE_DOWN, true);
            check.stateToIconFunction = iconSelector.updateValue;
			
			const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonUp;
            skinSelector.setValueForState(this.buttonDown, Button.STATE_DOWN, false);
            check.stateToSkinFunction = skinSelector.updateValue;
			
            check.defaultLabelProperties["textFormat"] = this.textFormat;
            check.defaultLabelProperties["embedFonts"] = true;
            
            check.gap = 2;
			check.padding = 2;
        }
		
	}
}