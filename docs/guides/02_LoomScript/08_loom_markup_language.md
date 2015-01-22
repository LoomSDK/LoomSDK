title: Loom Markup Language
description: Drive objects from XML
!------

### What is it?

The Loom Markup Language is an XML-based domain-specific language used to declare object hierarchies in LoomScript. LML lives in files with the `.lml` extension and is most often used to define UIs.

The basic idea behind LML is that it instantiates objects and calls special methods on parent nodes whenever a child is added. This allows for a very flexible and powerful way to declare complex hierarchies that are maintainable and tooling ready.

### A small example

The following snippet comes from the [CSS Example](http://docs.theengine.co/loom/1.1.3151/examples/CSSExample/index.html).

~~~xml
<loom2d.display.Sprite>

    <loom.css.StyleSheet source="assets/main.css"/>

    <loom2d.display.Image id="background" styleName="background" source="assets/Background.png"/>

    <loom2d.ui.SimpleButton id="myButton" upImage="assets/Button.png" downImage="assets/ButtonDown.png"/>

    <loom2d.ui.SimpleButton styleName="button2" upImage="assets/Button.png" downImage="assets/ButtonDown.png"/>

    <loom2d.ui.SimpleButton styleName="button3" upImage="assets/Button.png" downImage="assets/ButtonDown.png"/>

</loom2d.display.Sprite>
~~~

Let's break it down a bit.

1. We declare a `Sprite` object to be skinned with the CSS-sheet `main.css`. It will contain all of the sub-elements.
2. The `Image` tag has an `id` by which it can be referenced in LoomScript code, and the source points to the image file.
3. The first `SimpleButton` also has a unique id. The `upImage` and `downImage` attributes specify which image to display when the user clicks on the button.
4. The final two `SimpleButtons` have no unique id and cannot be referenced in LoomScript; they are static elements.

### Using LML in LoomScript

You must subclass whatever object is declared as the parent in the `.lml`. In our example, it is the Sprite.

~~~as3
class MainView extends Sprite
{
    // Nothing to do here- yet!
}
~~~

Optionally, if you've given some of your elements ids and wish to work on them in LoomScript, state their dependencies with the `[Bind]` annotation.

~~~as3
class MainView extends Sprite
{
    [Bind]
    public var background: Image;

    [Bind]
    public var myButton: SimpleButton;
}
~~~

From here, it's only a matter of loading the `.lml` file and you're good to go!

~~~as3
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
~~~

### Behind the scenes

LML will work with any set of classes. The main requirement is that the type of the root tag matches the object instance to which the LML is being `bind()`/`apply()`'ed. Instances that can have children must implement `loom.lml.ILMLParent`; nodes can also optionally implement `loom.lml.ILMLNode` to get callbacks as part of the LML deserialization.

### CSS and LML

If you only had the ability to declare elements and their hierarchy in LML, then that would be useful, but also leaving something to be desired. Fortunately, you can use CSS to manipulate and enhance properties of each element.

Each `styleName` attribute maps to a `#classname` attribute in CSS. `stylename="background"` resolves to the following piece of CSS (again from the CSSExample)

~~~css
#background {
    x: 480;
    y: 0;
    rotation: 1.57;
}
~~~

Additionally, each `id="name"` maps to a CSS id

~~~css
.myButton {
    x: 120;
    y: 20;
}
~~~

Now this is where LML shines! We can declaratively position, rotate, and skin our layout to (almost) our heart's content. We can even use Selectors to skin the same class for a different device.

~~~css
#button2 {
    x: 120;
    y: 120;
}

#button2[large] {
    x: 120;
    y: 160;
    scale: 0.6;
}
~~~

Here `button2` has two stylings. One for the normal case and one for tablet displays- the `[large]` selector. Even better, the styles are switched out automagically and intelligently so that you only have to define the styles and the framework handles the rest.

### Where to go from here

This has been a short introduction to the Loom Markup Language. You've learned how to read and declare your own `.lml` script, how to interface with LoomScript and the power of CSS to further style your layout. You've learned a lot and deserve a pat on the back, but don't forget that there's more to LML than what you saw here.

If you're interested in learning more, please see:

- The [advanced Poly Example](http://docs.theengine.co/loom/1.1.3151/examples/Poly/index.html) for a more in-depth view of LML and how you can define custom class hierarchies.
