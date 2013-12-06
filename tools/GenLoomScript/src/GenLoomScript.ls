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

        var scriptPaths:Vector.<String> = ["loom/script/common", "loom/script/native", "loom/script/reflection", "loom/script/runtime",
        "loom/script/serialize", "loom/script/native/core", "loom/script/native/core/system", "loom/script/native/core/system/Debugger",
        "loom/script/native/core/system/Metrics", "loom/script/native/core/system/Reflection", "loom/script/native/core/system/Socket",
        "loom/script/native/core/system/XML", "loom/script/native/core/system/Platform", "loom/script/native/core/system/Utils",
        "loom/script/native/core/assets", "loom/script/native/core/test"];

        override public function run():void
        {

            var path:String;

            for each (path in scriptPaths)
                walkSourcePath(path, scriptSources);

            for each (path in commonSources)
                walkSourcePath(path, commonSources);
            
            for each(var source in allSources)
                trace(source);
            
        }
    }
}