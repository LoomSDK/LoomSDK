package
{

    import loom.Application;    
    import loom2d.display.StageScaleMode;
    import loom2d.ui.SimpleLabel;
    import loom2d.math.Point;


    /**
     * Example showing how to use the loom.config classpath array to specify
     * source folders to compile
     */
    public class ClasspathExample extends Application
    {
        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var label = new SimpleLabel("assets/fonts/Curse-hd.fnt");
            label.text = "Classpath Example!";

            label.x = stage.stageWidth/2 - label.width/2;
            label.y = stage.stageHeight - 164;
            stage.addChild(label);

            var rc = new RelativeClass();
            trace(rc);

        }
    }
}