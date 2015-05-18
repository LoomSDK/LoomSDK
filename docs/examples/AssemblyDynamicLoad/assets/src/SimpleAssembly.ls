package
{
    import loom.Application;
    import loom2d.display.Shape;
    import system.Void;
    
    public class SimpleAssembly extends Application
    {
        
        override public static function main():void
        {
            trace("Hello asm.execute!");
        }
        
        override public function run():void
        {
            var s = new Shape(); stage.addChild(s); s.graphics.beginFill(0x00FF00); s.graphics.drawRect(40, 40, 50, 50);
            
            trace("Hello asm.run!");
        }
        
        override public function onTick() {
            trace("tick!");
            return super.onTick();
        }
        
    }
}