package
{
    import system.application.ConsoleApplication;    
    import system.platform.Path;

    /**
     * Generates core LoomScript from the full Loom source tree and places it in artifacts
     **/
    public class GenLoomScript extends ConsoleApplication
    {   

        override public function run():void
        {
            init();

            fillCMake();
        }

        function walkSourcePath(path:String, sources:Vector.<String>, headers:Vector.<String>, excludePaths:Vector.<String> = null)
        {
            Path.walkFiles(loomRoot + path, function(file:String) { 

                var filename = file.slice(loomRoot.length);

                if (excludePaths)
                {
                    for each(var path in excludePaths)
                    {
                        if (filename.substr(0, path.length) == path)
                            return;                            
                    }

                }

                var lastIndex = filename.lastIndexOf(".");

                if (lastIndex == -1)
                    return;

                var ext = filename.substr(lastIndex);    

                if (sourceFilters.contains(ext))
                    sources.push(filename);
                else if (headerFilters.contains(ext))
                    headers.push(filename);                
            });
        }

        function setDefines()
        {
            defines["LOOM_DISABLE_JEMALLOC"] = "";
            defines["HAVE_CXA_DEMANGLE"] = "";
            defines["NPERFORMANCE"] = "";
            defines["NTELEMETRY"] = "";
        }

        function setIncludes()
        {
            // base include dirs 
            includeDirs = ["${CMAKE_SOURCE_DIR}", "loom/common", "loom/vendor/jansson", "loom/vendor/lua/src", "loom/vendor/seatest"];
        }        

        function loadTemplates()
        {
            templateCMakeLists = File.loadTextFile("templates/CMakeLists.txt");
            templateRakefile = File.loadTextFile("templates/Rakefile");
        }

        function fillCMake()
        {
            var cmake = templateCMakeLists;

            var includes = "\ninclude_directories( ";
            for each (var include in includeDirs)
            {
                includes += include + " ";
            }

            includes += ")\n";

            var t = cmake.split("$INCLUDE_DIRS$");
            cmake = t[0] + includes + t[1];

            for each (var s in t)
                trace(s);

        }

        function init()
        {
            var path:String;

            loadTemplates();
            setDefines();
            setIncludes();

            var excludes:Vector.<String> = ["loom/script/compiler", "loom/script/native/core/compiler"];
            for each (path in corePaths)
                walkSourcePath(path, coreSources, coreHeaders, excludes);

            for each (path in compilerPaths)
                walkSourcePath(path, compilerSources, compilerHeaders, excludes);

            for each (path in vendorPaths)
                walkSourcePath(path, vendorSources, vendorHeaders);

            for each (path in luaPaths)
                walkSourcePath(path, luaSources, luaHeaders);

        }

        var loomRoot = "../../";
        var loomArtifacts = "../../artifacts";

        var sourceFilters:Vector.<String> = [".c", ".cpp", ".m", ".mm"];
        var headerFilters:Vector.<String> = [".h", ".hpp"];

        var coreSources = new Vector.<String>;     
        var coreHeaders = new Vector.<String>;     

        var compilerSources = new Vector.<String>;     
        var compilerHeaders = new Vector.<String>;             

        var vendorSources = new Vector.<String>;
        var vendorHeaders = new Vector.<String>;

        var luaSources = new Vector.<String>;
        var luaHeaders = new Vector.<String>;

        var defines = new Dictionary.<String, String>;
        var includeDirs:Vector.<String>;        

        var corePaths:Vector.<String> = [ "loom/common/xml", "loom/common/utils", "loom/common/core", "loom/common/platform", "loom/script" ];

        var compilerPaths:Vector.<String> = ["loom/script/compiler", "loom/script/native/core/compiler"];

        var vendorPaths:Vector.<String> = [ "loom/vendor/jansson", "loom/vendor/seatest" ];

        var luaPaths:Vector.<String> = [ "loom/vendor/lua/src" ];

        var templateCMakeLists:String;
        var templateRakefile:String;

    }


}