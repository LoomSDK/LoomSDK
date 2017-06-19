package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.textures.TextureSmoothing;
    import loom2d.display.Sprite;
    import ui.Theme;
    import feathers.controls.Button;
    import feathers.controls.Label;
    import feathers.controls.TextInput;

    /**
      * Feathers can be complicated, especially with themes, so this example
      * serves to show how to create a simple theme with multiple styles per
      * label and button.
      * 
      * See the KrushBlokk and FeathersComponentExplorer examples for more.
      */
    public class FeathersSimpleThemeExample extends Application
    {
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;
            
            // Different background color.
            stage.color = 0xD8C9A9;

            // Don't interpolate pixels for a rough pixel art look.
            TextureSmoothing.defaultSmoothing = TextureSmoothing.NONE;

            // Use a container to scale up everything for a bigger pixel font.
            var container = new Sprite();
            container.scale = 2;
            container.x = container.y = 10;
            stage.addChild(container);

            // Create the custom theme from src/ui/Theme.ls.
            // The theme applies itself to Feathers so no assignment is needed.
            new Theme();

            // First a simple label with all defaults.
            var defaultLabel:Label = new Label();
            // Different character capitalization controls character direction
            // in this particular font.
            defaultLabel.text = "Default laBel";
            container.addChild(defaultLabel);

            // A big label that can be used for e.g. titles.
            var titleLabel:Label = new Label();
            titleLabel.text = "TITLE LABeL";
            // This adds the "title" name to the label. Names are non-unique
            // style identifiers -- similar to classes in CSS.
            titleLabel.nameList.add("title");
            titleLabel.y = 20;
            container.addChild(titleLabel);

            // A smaller "header" label.
            var headerLabel:Label = new Label();
            headerLabel.text = "HEADER LABEL";
            // You can also assign a single name directly through "name".
            headerLabel.name = "header";
            headerLabel.y = 54;
            container.addChild(headerLabel);

            // And another style with dark-gray text.
            var subtitleLabel:Label = new Label();
            subtitleLabel.text = "SUBTITLe LABEL";
            subtitleLabel.nameList.add("subtitle");
            subtitleLabel.x = 130;
            subtitleLabel.y = 50;
            container.addChild(subtitleLabel);

            // And just to round it off, some normal light text.
            var lightLabel:Label = new Label();
            lightLabel.text = "Light LABEL";
            lightLabel.name = "light";
            lightLabel.x = 130;
            lightLabel.y = 60;
            container.addChild(lightLabel);

            // Simple default button, size is defined in the theme.
            var normalButton:Button = new Button();
            normalButton.y = 80;
            normalButton.label = "NoRmal Button";
            container.addChild(normalButton);

            // A button with a bigger label as defined by the "big" style.
            var bigButton:Button = new Button();
            bigButton.y = 105;
            bigButton.label = "Big button";
            bigButton.nameList.add("big");
            container.addChild(bigButton);

            // An inverted button type showing how to apply a different
            // label style per button state.
            var darkButton:Button = new Button();
            darkButton.y = 130;
            darkButton.label = "Dark buttoN";
            darkButton.nameList.add("dark");
            container.addChild(darkButton);

            var upperTextInput = new TextInput();
            upperTextInput.prompt = "Text input";
            upperTextInput.x = 130;
            upperTextInput.y = 80;
            upperTextInput.width = 80;
            upperTextInput.height = 20;
            container.addChild(upperTextInput);

            var lowerTextInput = new TextInput();
            lowerTextInput.prompt = "Text input";
            lowerTextInput.x = 130;
            lowerTextInput.y = 120;
            lowerTextInput.width = 80;
            lowerTextInput.height = 20;
            container.addChild(lowerTextInput);

        }
    }
}