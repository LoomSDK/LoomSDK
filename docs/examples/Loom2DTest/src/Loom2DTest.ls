package
{
    import loom.Application;

    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.textures.Texture;
    import loom2d.math.Point;
    import loom2d.ui.SimpleLabel;
    
    /**
     * Simple Loom2D Test
     */
    public class Loom2DTest extends Application
    {
        var label:SimpleLabel;

        var passed = true;

        function assert(value:Boolean, msg:String)
        {
            if (!value)
                fail(msg);
        }

        function fail(msg:String)
        {
            trace(msg);
            passed = false;
        }

        function testPoint()
        {
            var p1:Point;
            var p2:Point;
            var p3:Point;
            var p4:Point;
            var p5:Point;

            assert(p1.equals(p2), "p1 != p2");

            p1.x = 1001;
            p2 = p1;

            assert(p1.equals(p2), "p1 != p2 test 2");

            p1.y = 20;

            p3 += p1;

            assert(p3.x == 1001, "p3 != 1001");
            assert(p3.y == 20, "p3 != 20");

            p3 += p2;

            assert(p3.x == 2002, "p3 != 2002");
            assert(p3.y == 20, "p3 != 20");

            p1.x = 1;
            p1.y = 2;

            p2.x = 3;
            p2.y = 4;

            p4 = p1 + p2;
            p5 = p2 - p1;

            assert(p4.x == 4, "p4.x != 4");
            assert(p4.y == 6, "p4.y != 6");                 

            assert(p5.x == 2, "p5.x != 2");
            assert(p5.y == 2, "p5.y != 2");                 

            assert((p1 + p2).x == 4, "(p1 + p2).x != 4");
            assert((p1 + p2).y == 6, "(p1 + p2).y != 6");            

            assert((p1 - p2).x == -2, "(p1 - p2).x != -2)");
            assert((p1 - p2).y == -2, "(p1-+ p2).y != -2)");

            assert(p1.x == 1, "p1.x != 1");
            assert(p1.y == 2, "p1.y != 2");

            assert(p2.x == 3, "p2.x != 3");
            assert(p2.y == 4, "p2.y != 4");

        }

        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            label = new SimpleLabel("assets/Curse-hd.fnt", 320, 128);
            label.text = "Testing Loom2D";
            label.x = stage.stageWidth/2 - 320/2;
            label.y = stage.stageHeight/2 - 128/2;
            stage.addChild(label);

            testPoint();
            
            label.text = passed ? "Tests Passed" : "Tests Failed, please see console output";
        }
    }
}