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
                                                        vendorSources, vendorHeaders, luaSources, luaHeaders];

            var vector:Vector.<String>;
            var source:String;
            var destFolder:String;

            File.copy("templates/Rakefile", loomArtifacts + "/Rakefile");                    

            for each(vector in allSources)
            {
                for each (source in vector)
                {
                    destFolder = loomArtifacts + "/" + Path.folderFromPath(source);
                    Path.makeDir(destFolder);
                    File.copy("../../" + source, loomArtifacts + "/" + source);                    
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

            Path.makeDir(loomArtifacts + "/tools/lsc");
            File.copy("tools/lsc/main.cpp", loomArtifacts + "/tools/lsc/main.cpp");                       

            Path.makeDir(loomArtifacts + "/tools/loomrun");
            File.copy("tools/loomrun/main.cpp", loomArtifacts + "/tools/loomrun/main.cpp");                       

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
            });
        }

        function walkSDKPath(path:String, sources:Vector.<String>)
        {
            Path.walkFiles(loomRoot + path, function(file:String) {
                var filename = file.slice(loomRoot.length); 
                if (sdkExclusions.contains(filename))
                    return;
                sdkSources.push(filename);
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

            // sources
            var vendor = vendorSources.join(" ") + " " + vendorHeaders.join(" ");
            var core = coreSources.join(" ") + " " + coreHeaders.join(" ");
            var compiler = compilerSources.join(" ") + " " + compilerHeaders.join(" ");
            var lua = luaSources.join(" ") + " " + luaHeaders.join(" ");

            cmake = replaceTemplate(cmake, "$$VENDOR_SOURCE$$", vendor);
            cmake = replaceTemplate(cmake, "$$LUA_SOURCE$$", lua);
            cmake = replaceTemplate(cmake, "$$CORE_SOURCE$$", core);
            cmake = replaceTemplate(cmake, "$$COMPILER_SOURCE$$", compiler);   

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
                walkSDKPath(path, sdkSources);
            }

        }

        var loomRoot = "../../";
        var loomArtifacts = "../../artifacts/LoomScript";

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

        var sdkSources = new Vector.<String>;

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