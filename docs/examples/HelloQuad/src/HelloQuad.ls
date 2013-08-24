package
{

    import loom.Application;    
    import loom2d.display.StageScaleMode;
    import loom2d.display.Quad;   
    import loom2d.ui.SimpleLabel;
    import loom2d.math.Point;

    public class HelloQuad extends Application
    {
        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;

            var label = new SimpleLabel("assets/fonts/Curse-hd.fnt");
            label.text = "Hello Quad!";

            label.x = stage.stageWidth/2 - label.width/2;
            label.y = stage.stageHeight - 164;
            stage.addChild(label);

            var quad = new Quad(128, 128, 0xFF00FF00);
            quad.center();
            quad.x = 240;
            quad.y = 120;
            stage.addChild(quad);

        }
    }
}