package ui
{
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
    
    /**
      * A fairly simple theme supporting Labels and Buttons with different
      * styles / names.
      */
    public class Theme extends DisplayListWatcher
    {
        public const DEFAULT_SCALE9_GRID:Rectangle = new Rectangle(5, 5, 10, 10);
        
        public var textFormat:BitmapFontTextFormat;
        public var textFormatBig:BitmapFontTextFormat;
        public var textFormatLight:BitmapFontTextFormat;
        public var textFormatTitle:BitmapFontTextFormat;
        public var textFormatSubtitle:BitmapFontTextFormat;
        public var textFormatHeader:BitmapFontTextFormat;
        
        public var buttonUp:Scale9Textures;
        public var buttonDown:Scale9Textures;
        
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
            var assetPath = "assets/";
            var fontPath = assetPath + "fonts/";
            var uiPath = assetPath + "ui/";
            
            // Load the bitmap font from assets for later use
            // with the name "main".
            var font = fontPath + "kremlin-export.fnt";
            TextField.registerBitmapFont(BitmapFont.load(font), "main");
            
            // Simple text scaling control for the formats below.
            var scale = 4;
            
            // All the different formats used below are defined here.
            textFormat = new BitmapFontTextFormat("main", 8*scale, 0x000000);
            textFormatBig = new BitmapFontTextFormat("main", 2*8*scale, 0x000000);
            textFormatLight = new BitmapFontTextFormat("main", 8*scale, 0xFFFFFF);
            textFormatTitle = new BitmapFontTextFormat("main", 4*8*scale, 0xFFFFFF);
            textFormatSubtitle = new BitmapFontTextFormat("main", 1*8*scale, 0x4F4F4F);
            textFormatHeader = new BitmapFontTextFormat("main", 2*8*scale, 0xFFFFFF);
            
            // Simple background textures for buttons are defined here.
            const background = Texture.fromAsset(uiPath + "background-skin.png");
            const backgroundDown = Texture.fromAsset(uiPath + "background-down-skin.png");
            const background9 = new Scale9Textures(background, DEFAULT_SCALE9_GRID);
            const backgroundDown9 = new Scale9Textures(backgroundDown, DEFAULT_SCALE9_GRID);
            
            buttonUp = background9;
            buttonDown = backgroundDown9;
            
            // Assign control factories for each style.
            setInitializerForClass(Label, labelInitializer);
            setInitializerForClass(Label, labelInitializerLight, "light");
            setInitializerForClass(Label, labelInitializerTitle, "title");
            setInitializerForClass(Label, labelInitializerSubtitle, "subtitle");
            setInitializerForClass(Label, labelInitializerHeader, "header");
            setInitializerForClass(Button, buttonInitializer);
            setInitializerForClass(Button, buttonInitializerBig, "big");
            setInitializerForClass(Button, buttonInitializerDark, "dark");
        }
        
        /**
          * This is the base factory for a default label.
          * It sets the text format and the fact that the font is embedded.
          *
          * Other label initializers put their own spin on this base one. 
          */
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
        
        protected function labelInitializerSubtitle(label:Label)
        {
            labelInitializer(label);
            label.textRendererProperties["textFormat"] = textFormatSubtitle;
        }
        
        protected function labelInitializerHeader(label:Label)
        {
            labelInitializer(label);
            label.textRendererProperties["textFormat"] = textFormatHeader;
        }

        /**
          * The base button initializer / factory that sets a default label
          * text format.
          */
        protected function baseButtonInitializer(button:Button)
        {
            button.defaultLabelProperties["textFormat"] = textFormat;
            button.defaultLabelProperties["embedFonts"] = true;
        }
        
        /**
          * The default button initializer that sets up some properties, like
          * width and height as well as button up and down state backgrounds.
          */
        protected function buttonInitializer(button:Button)
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonUp;
            skinSelector.setValueForState(this.buttonDown, Button.STATE_DOWN, false);
            skinSelector.displayObjectProperties =
            {
                width: 120,
                height: 20
            };
            button.stateToSkinFunction = skinSelector.updateValue;
            this.baseButtonInitializer(button);
        }

        /**
          * The initializer for a big button inheriting from the default
          * one by just using a different, bigger, text format.
          */
        protected function buttonInitializerBig(button:Button)
        {
            buttonInitializer(button);
            button.defaultLabelProperties["textFormat"] = textFormatBig;
        }

        /**
          * An initializer for a dark button. This one customizes the
          * up and down button states by inverting them. It also defines a
          * different button size.
          */
        protected function buttonInitializerDark(button:Button)
        {
            const skinSelector:SmartDisplayObjectStateValueSelector = new SmartDisplayObjectStateValueSelector();
            skinSelector.defaultValue = this.buttonDown;
            skinSelector.setValueForState(this.buttonUp, Button.STATE_DOWN, false);
            skinSelector.displayObjectProperties =
            {
                width: 70,
                height: 20
            };
            button.stateToSkinFunction = skinSelector.updateValue;
            this.baseButtonInitializer(button);
            button.defaultLabelProperties["textFormat"] = textFormatLight;
            button.downLabelProperties["textFormat"] = textFormat;
        }
        
    }
}