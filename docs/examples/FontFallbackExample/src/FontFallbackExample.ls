package
{
    import loom.Application;
    import loom2d.display.Graphics;
    import loom2d.display.Quad;
    import loom2d.display.Shape;
    import loom2d.display.StageScaleMode;
    import loom2d.display.SVG;
    import loom2d.display.TextFormat;

    public class FontFallbackExample extends Application
    {
        private var g:Graphics;
        private var shape:Shape;
        
        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;
            //stage.scaleMode = StageScaleMode.NONE;
            stage.color = 0xF3F3F3;
            
            shape = new Shape();
            shape.x = 10;
            shape.y = 10;
            stage.addChild(shape);
            
            g = shape.graphics;
            
            g.beginFill(0xFCFCFC);
            
            g.drawTextLine(0, 0, "Crazy Frederick bought many very exquisite opal jewels.");
            
            g.textFormat(new TextFormat(null, 20));
            
            g.drawRect(0, 20, stage.stageWidth-shape.x*2, -20+stage.stageHeight-shape.y*2);
            
            g.drawTextBox(10, 30, -20+stage.stageWidth - shape.x*2, " ( ͡° ͜ʖ ͡°) Mild ᶘ ᵒᴥᵒᶅ Unicode (¬_¬) Powers! (*•̀ᴗ•́*)و ̑̑ ");
            
        }

    }
}
