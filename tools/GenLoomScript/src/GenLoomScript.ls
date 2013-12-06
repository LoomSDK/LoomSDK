package
{
    import system.application.ConsoleApplication;    
    import system.platform.Path;

    /**
     * Generates core LoomScript from the full Loom source tree and places it in artifacts
     **/
    public class GenLoomScript extends ConsoleApplication
    {   

        var loomRoot = "../../";

        var commonSources = new Vector.<String>;     
        var scriptSources = new Vector.<String>;     
        var allSources = new Vector.<String>;     

        function walkSourcePath(path:String, sources:Vector.<String>)
        {
            Path.walkFiles(loomRoot + path, function(file:String) { 
                var source = file.slice(loomRoot.length);
                sources.push(source);
                allSources.push(source);
            });
        }

        var commonPaths:Vector.<String> = [ "loom/common/xml", "loom/common/utils", "loom/common/core", "loom/common/platform" ];

        override public function run():void
        {
            var path:String;

            walkSourcePath("loom/script", scriptSources);

            for each (path in commonPaths)
                walkSourcePath(path, commonSources);
            
            for each(var source in allSources)
                trace(source);
            
        }
    }
}