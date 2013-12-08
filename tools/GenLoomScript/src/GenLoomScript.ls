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

            if (!Path.dirExists(loomArtifacts))
                Path.makeDir(loomArtifacts);

            File.writeTextFile(loomArtifacts + "/" + "CMakeLists.txt", cmakeListsTxt);

            copyFiles();
        }

        function copyFiles()
        {
            var allSources:Vector.<Vector.<String> > = [coreSources, coreHeaders, compilerSources, compilerHeaders, 
                                                        vendorSources, vendorHeaders, luaSources, luaHeaders, objCSources];

            var vector:Vector.<String>;
            var source:String;
            var destFolder:String;

            File.copy("templates/Rakefile", loomArtifacts + "/Rakefile");                    

            for each(vector in allSources)
            {
                for each (source in vector)
                {
                    destFolder = loomArtifacts + "/source/" + Path.folderFromPath(source);
                    Path.makeDir(destFolder);
                    File.copy("../../" + source, loomArtifacts + "/source/" + source);                    
                }
            }

            for each (source in sdkSources)
            {
                destFolder = loomArtifacts + "/" + Path.folderFromPath(source);
                Path.makeDir(destFolder);
                File.copy("../../" + source, loomArtifacts + "/" + source);                    
            }

            for each (source in sdkBuildFiles)
            {
                File.copy("../../sdk/src/" + source, loomArtifacts + "/sdk/src/" + source);                       
            }

            Path.makeDir(loomArtifacts + "/source/tools/lsc");
            File.copy("tools/lsc/main.cpp", loomArtifacts + "/source/tools/lsc/main.cpp");                       

            Path.makeDir(loomArtifacts + "/source/tools/loomrun");
            File.copy("tools/loomrun/main.cpp", loomArtifacts + "/source/tools/loomrun/main.cpp");                       

            Path.makeDir(loomArtifacts + "/source/tools/bin2c");
            File.copy("../../tools/bin2c/bin2c.c", loomArtifacts + "/source/tools/bin2c/bin2c.c");                       


            Path.makeDir(loomArtifacts + "/sdk/bin");
            Path.makeDir(loomArtifacts + "/sdk/libs");

        }

        function walkSourcePath(path:String, sources:Vector.<String>, headers:Vector.<String>, excludePaths:Vector.<String> = null)
        {
            Path.walkFiles(loomRoot + path, function(file:String) {

                var filename = file.slice(loomRoot.length); 

                if (sourceExclusions.contains(filename))
                {
                    return;
                }                            

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
                else if (objCFilters.contains(ext))
                    objCSources.push(filename);
            });
        }

        function walkSDKPath(path:String, sources:Vector.<String>)
        {
            Path.walkFiles(loomRoot + path, function(file:String) {
                var filename = file.slice(loomRoot.length); 
                if (sdkExclusions.contains(filename))
                    return;
                sources.push(filename);
            });
        }


        function loadTemplates()
        {
            templateCMakeLists = File.loadTextFile("templates/CMakeLists.txt");
        }

        function replaceTemplate(source:String, search:String, replace:String):String
        {
            var t = source.split(search);
            source = t[0] + replace + t[1];
            return source;
        }        

        function fillCMake()
        {
            var cmake = templateCMakeLists;

            
            var process = function(sources:Vector.<String>):String
            {
                var tmp = [];

                sources.every(function(item:Object, index:Number, v:Vector):Boolean {   
                    tmp.push("source/" + item);
                    return true; });              

                return tmp.join("\n    ");
            };

            // sources
            var vendor = process(vendorSources) + "\n    " + process(vendorHeaders);
            var core = process(coreSources) + "\n    " + process(coreHeaders);
            var compiler = process(compilerSources) + "\n    " + process(compilerHeaders);
            var lua = process(luaSources) + "\n    " + process(luaHeaders);
            var objC = process(objCSources) + "\n";

            var sdk = sdkSystemSources.join("\n    ");

            cmake = replaceTemplate(cmake, "$$VENDOR_SOURCE$$", vendor);
            cmake = replaceTemplate(cmake, "$$LUA_SOURCE$$", lua);
            cmake = replaceTemplate(cmake, "$$CORE_SOURCE$$", core);
            cmake = replaceTemplate(cmake, "$$COMPILER_SOURCE$$", compiler);   
            cmake = replaceTemplate(cmake, "$$OBJC_SOURCE$$", objC);  
            cmake = replaceTemplate(cmake, "$$SDK_SOURCE$$", sdk);   

            cmakeListsTxt = cmake;         
        }

        function init()
        {
            var path:String;

            loadTemplates();

            var excludes:Vector.<String> = ["loom/script/compiler", "loom/script/native/core/compiler"];
            for each (path in corePaths)
                walkSourcePath(path, coreSources, coreHeaders, excludes);

            for each (path in compilerPaths)
                walkSourcePath(path, compilerSources, compilerHeaders);

            for each (path in vendorPaths)
                walkSourcePath(path, vendorSources, vendorHeaders);

            for each (path in luaPaths)
                walkSourcePath(path, luaSources, luaHeaders);

            // SDK paths
            for each (path in sdkPaths)
            {

                if (path == "sdk/src/system")
                {

                    walkSDKPath(path, sdkSystemSources);
                    for each (var source in sdkSystemSources)
                    {
                        sdkSources.push(source);
                    }
                }
                else
                    walkSDKPath(path, sdkSources);

            }

        }

        var loomRoot = "../../";
        var loomArtifacts = "../../artifacts/LoomScript";

        var sourceFilters:Vector.<String> = [".c", ".cpp"];
        var objCFilters:Vector.<String> = [".m", ".mm"];
        var headerFilters:Vector.<String> = [".h", ".hpp"];

        var objCSources = new Vector.<String>;

        var coreSources = new Vector.<String>;     
        var coreHeaders = new Vector.<String>;     

        var compilerSources = new Vector.<String>;     
        var compilerHeaders = new Vector.<String>;             

        var vendorSources = new Vector.<String>;
        var vendorHeaders = new Vector.<String>;

        var luaSources = new Vector.<String>;
        var luaHeaders = new Vector.<String>;

        var sdkSources = new Vector.<String>;
        var sdkSystemSources = new Vector.<String>;

        var sdkBuildFiles:Vector.<String> = ["Benchmarks.build", "Compiler.build", "LDB.build", "System.build", "Tests.build", "UnitTest.build"];

        var sdkPaths:Vector.<String> = [ "sdk/src/system", "sdk/src/test", "sdk/src/benchmark", "sdk/src/compiler", "sdk/src/unittest"];

        var corePaths:Vector.<String> = [ "loom/common/xml", "loom/common/utils", "loom/common/core", "loom/common/platform", "loom/script" ];

        var compilerPaths:Vector.<String> = ["loom/script/compiler", "loom/script/native/core/compiler"];

        var vendorPaths:Vector.<String> = [ "loom/vendor/jansson", "loom/vendor/seatest", "loom/vendor/jemalloc-3.4.0" ];

        var luaPaths:Vector.<String> = [ "loom/vendor/lua/src" ];

        // these really should be moved down to the engine module
        var sourceExclusions:Vector.<String> = ["loom/common/platform/platformAdMobIOS.mm", "loom/common/platform/EBPurchase.m", 
                                                "loom/common/platform/platformWebViewIOS.mm", "loom/common/platform/platformVideoIOS.mm",
                                                "loom/common/platform/RootViewController.mm", "loom/script/native/core/assets/lmAssets.cpp",
                                                "loom/script/native/core/system/Platform/lmGamePad.cpp"];

        var sdkExclusions:Vector.<String> = ["sdk/src/system/Platform/Gamepad.ls"];

        var templateCMakeLists:String;
        var cmakeListsTxt:String;

    }


}