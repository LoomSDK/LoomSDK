package
{
    import loom.Application;
    import loom2d.display.Shape;
    import system.platform.File;
    import system.reflection.Assembly;
    import system.Void;
    
    public class AssemblyDynamicLoad extends Application
    {
        
        override public function run():void
        {
            var s = new Shape(); stage.addChild(s); s.graphics.beginFill(0xFF0000); s.graphics.drawRect(20, 20, 50, 50);
            
            trace("Hello?");
            var asm = Assembly.loadBytes(File.loadBinaryFile("assets/bin/Main.loom"));
            asm.run();
            trace("Hey?");
            
        }
        
    }
}