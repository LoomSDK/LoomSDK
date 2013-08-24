title: Loom Markup Language
description: Drive objects from XML.
!------

The Loom Markup Language is an XML based, domain specific language used in declaring object hierarchies in LoomScript. LML lives in files with the `.lml` extension and is most often used to define UIs.

The basic idea behind LML is that it instantiates objects and calls special methods on parent nodes whenever a child is added. This allows for a very flexible and powerful way to declare complex hierarchies that are maintainable and tooling ready.

The following snippets come from the CSSExample.

~~~xml
<loom2d.display.Sprite>

    <loom.css.StyleSheet source="assets/main.css"/>

    <loom2d.display.Image id="background" styleName="background" source="assets/Background.png"/>

    <loom2d.ui.SimpleButton id="myButton" upImage="assets/Button.png" downImage="assets/ButtonDown.png"/>
    
    <loom2d.ui.SimpleButton styleName="button2" upImage="assets/Button.png" downImage="assets/ButtonDown.png"/>
    
    <loom2d.ui.SimpleButton styleName="button3" upImage="assets/Button.png" downImage="assets/ButtonDown.png"/>

</loom2d.display.Sprite>
~~~

And here is how we use that LML file from script:

~~~as3
package
{
    import loom.lml.LML;
    import loom.Application;    
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;    
    import loom2d.display.Sprite;    
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
    import loom2d.ui.SimpleButton;

    /**
     * Example of Loom CSS features, please note that on tablets
     * DisplayProfile.LARGE will be used in the CSS which will change the formatting
     * and display differently than when run on the Desktop
     */
    class CSSExample extends Application
    {
        override public function run()
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var view:MainView = new MainView();
            stage.addChild(view);

            LML.bind("assets/main.lml", view);

            view.myButton.onClick += function() {
                trace("Button 1 clicked");                
            };
        }
    }
}
~~~

## Injection

You can also get references to objects by ID from your script code via LML binding:

~~~as3
// class to bind to the main.lml file
class MainView extends Sprite
{
    [Bind]
    public var background:Image;

    [Bind]
    public var myButton:SimpleButton;
}
~~~

And here is how the XML should look:

~~~xml
<loom2d.display.Sprite>

    <loom.css.StyleSheet source="assets/main.css"/>

    <!-- id maps to member on class. -->
    <loom2d.display.Image id="background" styleName="background" source="assets/Background.png"/>

    <!-- id maps to member on class. -->
    <loom2d.ui.SimpleButton id="myButton" upImage="assets/Button.png" downImage="assets/ButtonDown.png"/>
    
    <loom2d.ui.SimpleButton styleName="button2" upImage="assets/Button.png" downImage="assets/ButtonDown.png"/>
    
    <loom2d.ui.SimpleButton styleName="button3" upImage="assets/Button.png" downImage="assets/ButtonDown.png"/>

</loom2d.display.Sprite>
~~~

## Behind The Scenes

LML will work with any set of classes. The main requirement is that the type of the root tag matches the object instance to which the LML is being `bind()`/`apply()`'ed. Instances that can have children must implement `loom.lml.ILMLParent`; nodes can also optionally implement `loom.lml.ILMLNode` to get callbacks as part of the LML deserialization.