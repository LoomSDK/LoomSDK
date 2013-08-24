package
{
    import system.application.ConsoleApplication;    

    public class Main extends ConsoleApplication
    {
        override public function run():void
        {
            trace("Hello");

            for (var i = 0; i < CommandLine.getArgCount(); i++)
            {
            	trace(CommandLine.getArg(i));
            }

            
        }
    }
}