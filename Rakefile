require 'rubygems'
require 'rbconfig'

puts "== Executing as '#{ENV['USER']}' =="

###############################
# BUILD CONFIGURATION VARIABLES
###############################

# Specify the build target - Debug, Release, RelMinSize, RelWithDebug
$buildTarget="Release" # "Debug"

# What version of the android SDK are going to target? Note you also need to
# update the Android project and manifest to match.
$targetAndroidSDK="android-13"

# What Android target are we going to build? debug and release are the main
# options but there are more. (see http://developer.android.com/tools/building/building-cmdline.html)
$targetAndroidBuildType = "release" # "debug"

# What version of iOS SDK are we going to build for? If you set IOS_SDK in your
# environment, it will override.
if(ENV['IOS_SDK'])
  $targetIOSSDK=ENV['IOS_SDK']
else
  $targetIOSSDK="6.0"
end

# If 1, then we link against LuaJIT. If 0, we use classic Lua VM.
$doBuildJIT=1

# Allow disabling Loom doc generation, as it can be very slow.
# Disabled by default, set environment variable 'LOOM_BUILD_DOCS'
$buildDocs = ENV['LOOM_BUILD_DOCS'] == "1" || ENV['LOOM_BUILD_DOCS'] == "true"

######################################
# END OF BUILD CONFIGURATION VARIABLES
######################################

# Ruby version check.
if RUBY_VERSION < '1.8.7'
  abort("Please update your version of ruby. Loom requires 1.8.7 or newer.")
else
  puts "Loom Rakefile running on Ruby #{RUBY_VERSION}"
end

include RbConfig

case CONFIG['host_os']
   when /mswin|windows|mingw32/i
      $LOOM_HOST_OS = "windows"
   when /darwin/i
      $LOOM_HOST_OS = "darwin"
   when /linux-gnu/i
      $LOOM_HOST_OS = "linux"
   else
      abort("Unknown host config: Config::CONFIG['host_os']: #{Config::CONFIG['host_os']}")
end

$CMAKE_VERSION = %x[cmake --version]
$CMAKE_REQUIRED_VERSION = '2.8.9'

#TODO: Make this platform independent
#https://theengineco.atlassian.net/browse/LOOM-659
if $LOOM_HOST_OS == 'darwin'
    # CMAKE version check
    if(%x[which cmake].empty? || Gem::Version.new($CMAKE_VERSION.gsub("cmake version ", "")) < Gem::Version.new($CMAKE_REQUIRED_VERSION))
      abort("The rakefile requires cmake version #{$CMAKE_REQUIRED_VERSION} and above, please go to http://www.cmake.org/ and install the latest version.")
    else
      puts "Running #{$CMAKE_VERSION}"
    end

end

# Report configuration variables and validate them.
puts "*** Using JIT? = #{$doBuildJIT}"
puts "*** Build Type = #{$buildTarget}"
puts "*** AndroidSDK = #{$targetAndroidSDK} AndroidBuildType = #{$targetAndroidBuildType}"
puts "*** iOS SDK Version = #{$targetIOSSDK}"
puts "*** Build Loom Docs = #{$buildDocs}"

# $buildDebugDefine will trigger the LOOM_DEBUG define if this is a Debug build target
if $buildTarget == "Debug"
  $buildDebugDefine="-DLOOM_IS_DEBUG=1"
else
  $buildDebugDefine="-DLOOM_IS_DEBUG=0"
end

# How many cores should we use to build?
if $LOOM_HOST_OS == 'darwin'
  $numCores = Integer(`sysctl hw.ncpu | awk '{print $2}'`)
elsif $LOOM_HOST_OS == 'windows'
  $numCores = ENV['NUMBER_OF_PROCESSORS']
else 
  $numCores = Integer(`cat /proc/cpuinfo | grep processor | wc -l`)
end

puts "*** Building with #{$numCores} cores."

# Windows specific checks and settings
if $LOOM_HOST_OS == 'windows'
  # This gets the true architecture of the machine, not the target architecture of the currently executing binary (that is what %PROCESSOR_ARCHITECTURE% returns)
  WINDOWS_PROCARCH_BITS = `reg query "HKLM\\System\\CurrentControlSet\\Control\\Session Manager\\Environment" /v PROCESSOR_ARCHITECTURE`.split("AMD")[1].split(" ")[0].split("\n")[0]
  # Is this a 32 or a 64 bit OS?
  if WINDOWS_PROCARCH_BITS == "64"
    puts "*** Windows x64"
    WINDOWS_ISX64 = "1"
    WINDOWS_ANDROID_PREBUILT_DIR = "windows-x86_64"
  else
    puts "*** Windows x86"
    WINDOWS_PROCARCH_BITS = "32"
    WINDOWS_ANDROID_PREBUILT_DIR = "windows"
  end
  #Dir.chdir("build") do
  #  sh "call windowsBuildHelper.bat"
  #end
else
  # Some sensible defaults...
  WINDOWS_PROCARCH_BITS = "32"
  WINDOWS_ISX64 = "0"
  WINDOWS_ANDROID_PREBUILT_DIR = "windows"
end

# Determine the APK name.
if $targetAndroidBuildType == "release"
  $targetAPKName = "LoomDemo-release-unsigned.apk"
elsif $targetAndroidBuildType == "debug"
  $targetAPKName = "LoomDemo-debug-unaligned.apk"
else
  abort("Don't know how to generate the APK name for Android build target type #{$targetAndroidBuildType}! Please update this if block.")
end

$OUTPUT_DIRECTORY = "artifacts"
$LOOM_VERSION = File.new("VERSION").read

require 'rake/clean'
require 'rake/packagetask'
require 'pathname'
require 'shellwords'

if $LOOM_HOST_OS == 'windows' 
    $LSC_BINARY = "artifacts\\lsc.exe"
else
    $LSC_BINARY = "artifacts/lsc"
end

#############
# BUILD TASKS
#############

CLEAN.include ["cmake_android", "cmake_osx", "cmake_ios", "cmake_msvc", "cmake_ubuntu", "build/lua_*/**", "application/android/bin", "application/ouya/bin"]
CLEAN.include ["build/**/lib/**", "artifacts/**"]
CLOBBER.include ["**/*.loom",$OUTPUT_DIRECTORY]
CLOBBER.include ["**/*.loomlib",$OUTPUT_DIRECTORY]

task :default => :list_targets

task :clobber, :force do |t, args|
  args.with_defaults( :force => false )
  
  puts args[:force]
  # forcing
  if args[:force] == "force"
    sh "git clean -fdx"
  else
    # prompt user before running
    puts "\n\nWARNING: THIS IS A DESTRUCTIVE ACTION"
    puts "You are about to remove the following files:"
    puts `git clean -fdx -n`
    puts "Are you sure you want to remove these files? (yes/no)"
    their_sure = STDIN.gets
    if their_sure.chomp! == "yes" || their_sure.chomp! == "y"
      sh "git clean -fdx"
    else
      puts "Phew, that was close!"
    end
  end
end

namespace :generate do

  desc "Generate XCode projects for OS X"
  task :xcode_osx do
    FileUtils.mkdir_p("cmake_osx")    
    Dir.chdir("cmake_osx") do
      sh "cmake ../ -G Xcode -DLOOM_BUILD_JIT=#{$doBuildJIT} -DCMAKE_BUILD_TYPE=#{$buildTarget} #{$buildDebugDefine}"
    end
  end

  desc "Generate XCode projects for iOS"
  task :xcode_ios do
    FileUtils.mkdir_p("cmake_ios")
    Dir.chdir("cmake_ios") do
      sh "cmake ../ -G Xcode -DLOOM_BUILD_IOS=1 -DLOOM_BUILD_JIT=#{$doBuildJIT} -DLOOM_IOS_VERSION=#{$targetIOSSDK} -DCMAKE_BUILD_TYPE=#{$buildTarget} #{$buildDebugDefine}"
    end
  end

  desc "Generate VS2010 projects"
  task :vs2010 do
    FileUtils.mkdir_p("cmake_msvc")
    Dir.chdir("cmake_msvc") do
      sh "cmake .. -G \"Visual Studio 10\" -DLOOM_BUILD_JIT=#{$doBuildJIT} -DLOOM_BUILD_NUMCORES=#{$numCores} -DCMAKE_BUILD_TYPE=#{$buildTarget} #{$buildDebugDefine}"
    end
  end

  desc "Generate VS2012 projects"
  task :vs2012 do
    FileUtils.mkdir_p("cmake_msvc")
    Dir.chdir("cmake_msvc") do
      sh "cmake .. -G \"Visual Studio 11\" -DLOOM_BUILD_JIT=#{$doBuildJIT} -DLOOM_BUILD_NUMCORES=#{$numCores} -DCMAKE_BUILD_TYPE=#{$buildTarget} #{$buildDebugDefine}"
    end
  end

  desc "Generate Makefiles for Ubuntu"
  task :makefiles_ubuntu do
    FileUtils.mkdir_p("cmake_ubuntu")    
    Dir.chdir("cmake_ubuntu") do
      sh "cmake ../ -G \"Unix Makefiles\" -DLOOM_BUILD_JIT=#{$doBuildJIT} -DCMAKE_BUILD_TYPE=#{$buildTarget} #{$buildDebugDefine}"
    end
  end

  desc "Generates API documentation for the loomscript sdk"
  task :docs => ['build:desktop'] do

    if $buildDocs || ARGV.include?('generate:docs')
      Dir.chdir("docs") do
        ruby "main.rb"
      end

      FileUtils.mkdir_p "artifacts/docs"
      FileUtils.cp_r "docs/output/.", "artifacts/docs/"
    else
      puts "Skipping docs due to env.BUILD_LOOM_DOCS being false."
    end
  end

  desc "Generates API documentation for the loomscript sdk"
  task :test_docs, [:class] do |t, args|

    puts "===== Running Test Docs #{args[:class]} ====="

    puts "===== Compiling Core Scripts ====="
    Dir.chdir("sdk") do
      sh "../artifacts/lsc Main.build"
    end

    puts "===== Generating Docs ====="
    Dir.chdir("docs") do
      ruby "main.rb test #{args[:class]}"
    end
  end

end

desc "Opens the docs in a web browser"
task :docs => ['generate:docs'] do
  if $LOOM_HOST_OS == 'windows'
    `start artifacts/docs/index.html`
  else
    `open artifacts/docs/index.html`
  end
  
end 

namespace :utility do

  desc "Builds lsc if it doesn't exist"
  file $LSC_BINARY => "build:desktop" do
    puts " *** lsc built!"
  end
  
  desc "Compile scripts and report any errors."
  task :compileScripts => $LSC_BINARY do
    puts "===== Compiling Core Scripts ====="
    Dir.chdir("sdk") do
      sh "../artifacts/lsc Main.build"
    end
  end

  desc "Compile demos and report any errors"
  task :compileDemos => $LSC_BINARY do

    Dir["docs/examples/*"].each do | demo |
      next unless File.directory? demo

      demoName = File.basename(demo)

      next if demoName == '.' or demoName == '..'

      Rake::Task['utility:compileDemo'].invoke(demoName)
      Rake::Task['utility:compileDemo'].reenable
    end

  end

  desc "Compile demo"
  task :compileDemo, [:name] => $LSC_BINARY do |t, args|
      puts "===== Compiling #{args[:name]} ====="
      FileUtils.cp_r("./sdk/libs", "./docs/examples/#{args[:name]}")
      FileUtils.mkdir_p("./docs/examples/#{args[:name]}/bin")
      expandedArtifactsPath = File.expand_path($OUTPUT_DIRECTORY)
      Dir.chdir("docs/examples/#{args[:name]}") do
        sh "#{expandedArtifactsPath}/lsc"
      end
  end

  desc "Run demo"
  task :runDemo, [:name] => $LSC_BINARY do |t, args|
      puts "===== Running #{args[:name]} ====="
      expandedArtifactsPath = File.expand_path($OUTPUT_DIRECTORY)
      if $LOOM_HOST_OS == 'darwin'
        Rake::Task["build:osx"].invoke        
        Rake::Task["utility:compileScripts"].invoke        
        FileUtils.cp_r("./sdk/libs", "./docs/examples/#{args[:name]}")
        FileUtils.mkdir_p("./docs/examples/#{args[:name]}/bin") 
        Dir.chdir("docs/examples/#{args[:name]}") do
          sh "#{expandedArtifactsPath}/lsc"
          sh "#{expandedArtifactsPath}/osx/LoomDemo.app/Contents/MacOS/LoomDemo"
        end
      else
        Rake::Task["build:windows"].invoke        
        Rake::Task["utility:compileScripts"].invoke        
        FileUtils.cp_r("./sdk/libs", "./docs/examples/#{args[:name]}")
        FileUtils.mkdir_p("./docs/examples/#{args[:name]}/bin") 
        Dir.chdir("docs/examples/#{args[:name]}") do
          sh "#{expandedArtifactsPath}/lsc.exe"
          sh "#{expandedArtifactsPath}/windows/LoomDemo.exe"
        end
      end
  end

  desc "Run the LoomDemo in artifacts"
  task :run => "build:desktop" do

    puts "===== Launching Application ====="

  if $LOOM_HOST_OS == 'darwin'
  
    appPath = Dir.glob("artifacts/osx/*.app")[0]
    appPrefix = get_app_prefix(appPath)

    # Run it.
    Dir.chdir(appPath) do
      sh "./Contents/MacOS/#{appPrefix}"
    end
  else
    
    #Run it under Windows
    Dir.chdir("artifacts/windows") do
      sh "LoomDemo.exe"
    end
  end
  
  end
  
  desc "Run app under GDB on OSX"
  task :debug => ['build:osx'] do
    puts "===== Launching Application ====="

    appPath = Dir.glob("artifacts/osx/*.app")[0]
    appPrefix = get_app_prefix(appPath)

    # Run it.
    Dir.chdir(appPath) do
      sh "gdb ./Contents/MacOS/#{appPrefix}"
    end
  end

end

namespace :build do
  
  desc "Build Everything"
  task :all do
    puts "building all"
    Rake::Task["build:desktop"].invoke
    Rake::Task["build:android"].invoke
    Rake::Task["build:ouya"].invoke
    if $LOOM_HOST_OS == 'darwin'
      Rake::Task["build:ios"].invoke
    end
  end

  desc "Builds the native desktop platform (OSX or Windows)"
  task :desktop do
    if $LOOM_HOST_OS == 'windows'
      Rake::Task["build:windows"].invoke
    elsif $LOOM_HOST_OS == 'darwin'
      Rake::Task["build:osx"].invoke
    else
      Rake::Task["build:ubuntu"].invoke
    end
  end

  desc "Builds fruitstrap"
  task :fruitstrap do
    Dir.chdir("tools/fruitstrap") do
      sh "make fruitstrap"
    end
    FileUtils.cp("tools/fruitstrap/fruitstrap", "artifacts")
  end
  
  desc "Builds OS X"
  task :osx => ['build/luajit_x86/lib/libluajit-5.1.a'] do

    # OS X build is currently not supported under Windows
    if $LOOM_HOST_OS != 'windows'

      puts "== Building OS X =="
      FileUtils.mkdir_p("cmake_osx")    
      Dir.chdir("cmake_osx") do
        sh "cmake ../ -DLOOM_BUILD_JIT=#{$doBuildJIT} -G Xcode -DCMAKE_BUILD_TYPE=#{$buildTarget} #{$buildDebugDefine}"
        sh "xcodebuild -configuration #{$buildTarget}"
      end
      
      # copy asset agent
      FileUtils.cp("cmake_osx/tools/assetAgent/#{$buildTarget}/libassetAgent.so", "artifacts")
      
      # copy libs
      FileUtils.cp_r("sdk/libs", "artifacts/")

      # build ldb
      Dir.chdir("sdk") do
        sh "../artifacts/lsc LDB.build"
      end

      FileUtils.cp_r("sdk/bin/LDB.loom", "artifacts")

      #copy assets
      FileUtils.mkdir_p("artifacts/assets")

    end

  end

  desc "Builds iOS"
  task :ios, [:sign_as] => ['build/luajit_ios/lib/libluajit-5.1.a', 'utility:compileScripts', 'build:fruitstrap'] do |t, args|

    # iOS build is currently not supported under Windows
    if $LOOM_HOST_OS != 'windows'

      puts "== Building iOS =="

      check_ios_sdk_version! $targetIOSSDK

      if(ENV['IOS_MOBILE_PROVISION'])
        $iosProvision = ENV['IOS_MOBILE_PROVISION']
      else
        puts "!!!! PLEASE SET 'IOS_MOBILE_PROVISION' IN YOUR ENVIRONMENT"
        exit 1
      end

      unless File.exists? $iosProvision
        puts "!!!! iOS Mobile Provision doesn't exist at #{$iosProvision}, please fix your IOS_MOBILE_PROVISION env variable."
        exit 1
      end
      puts "*** Mobile Provision = #{$iosProvision}"

      if(ENV['IOS_SIGNING_IDENTITY'])
        puts "Using IOS Signing Identity from ENV"
        args.with_defaults(:sign_as => ENV['IOS_SIGNING_IDENTITY'])
      else
        args.with_defaults(:sign_as => "iPhone Developer")
      end
      puts "*** Signing Identity = #{args.sign_as}"
      
      FileUtils.mkdir_p("cmake_ios")

      # TODO: Find a way to resolve resources in xcode for ios.
      Dir.chdir("cmake_ios") do
        sh "cmake ../ -DLOOM_BUILD_IOS=1 -DLOOM_BUILD_JIT=#{$doBuildJIT} -DLOOM_IOS_VERSION=#{$targetIOSSDK} #{$buildDebugDefine} -G Xcode"
        sh "xcodebuild -configuration #{$buildTarget}"
      end

      # TODO When we clean this up... we should have get_app_prefix return and object with, appPath, 
      # appNameMatch, appName and appPrefix
      
      # Find the .app in the build folder.
      appPath = Dir.glob("cmake_ios/application/#{$buildTarget}-iphoneos/*.app")[0]
      puts "Application path found: #{appPath}"
      appNameMatch = /\/(\w*\.app)$/.match(appPath)
      appName = appNameMatch[0]
      puts "Application name found: #{appName}"  

      # Make it ito an IPA!
      full_output_path = Pathname.new("#{$OUTPUT_DIRECTORY}/ios").realpath
      package_command = "/usr/bin/xcrun -sdk iphoneos PackageApplication"
      package_command += " -v '#{appPath}'"
      package_command += " -o '#{full_output_path}/#{appName}.ipa'"
      package_command += " --sign '#{args.sign_as}'"
      package_command += " --embed '#{$iosProvision}'"
      sh package_command
    end
  end

  desc "Builds Windows"
  task :windows => ['build\luajit_windows\lua51.lib'] do  
    puts "== Building Windows =="

    FileUtils.mkdir_p("cmake_msvc")
    Dir.chdir("cmake_msvc") do
      sh "../build/win-cmake.bat #{$doBuildJIT} #{$numCores} \"#{$buildDebugDefine}\""
      sh "msbuild LoomEngine.sln /p:Configuration=#{$buildTarget}"
    end
    
    Rake::Task["utility:compileScripts"].invoke

    # build ldb
    Dir.chdir("sdk") do
      sh "../artifacts/lsc LDB.build"
    end

    # copy libs
    FileUtils.cp_r("sdk/libs", "artifacts/")
    FileUtils.cp_r("sdk/bin/LDB.loom", "artifacts")

    puts "Copying to #{$OUTPUT_DIRECTORY}/windows"
    
    FileUtils.cp_r('./sdk/bin', './artifacts/windows')
    FileUtils.cp_r('./sdk/assets', './artifacts/windows')
    
    #copy assets
    FileUtils.mkdir_p("artifacts/assets")
  end

  desc "Builds Android APK"
  task :android => ['build/luajit_android/lib/libluajit-5.1.a', 'utility:compileScripts'] do
    puts "== Building Android =="

    if $LOOM_HOST_OS == "windows"
      # WINDOWS
      FileUtils.mkdir_p("cmake_android")
      Dir.chdir("cmake_android") do
        sh "cmake -DCMAKE_TOOLCHAIN_FILE=../build/cmake/loom.android.toolchain.cmake #{$buildDebugDefine} -DANDROID_NDK_HOST_X64=#{WINDOWS_ISX64} -DANDROID_ABI=armeabi-v7a  -DLOOM_BUILD_JIT=#{$doBuildJIT} -DANDROID_NATIVE_API_LEVEL=14 -DCMAKE_BUILD_TYPE=#{$buildTarget} -G\"MinGW Makefiles\" -DCMAKE_MAKE_PROGRAM=\"%ANDROID_NDK%\\prebuilt\\#{WINDOWS_ANDROID_PREBUILT_DIR}\\bin\\make.exe\" .."
        sh "cmake --build ."
      end

      puts "*** Building against AndroidSDK " + $targetAndroidSDK
      api_id = get_android_api_id($targetAndroidSDK)

      Dir.chdir("loom/engine/cocos2dx/platform/android/java") do
        sh "android update project --name Cocos2DLib --subprojects --target #{api_id} --path ."
      end
      
      Dir.chdir("application/android") do
        sh "android update project --name LoomDemo --subprojects --target #{api_id} --path ."
      end
      
      FileUtils.mkdir_p "application/android/assets"
      FileUtils.mkdir_p "application/android/assets/assets"
      FileUtils.mkdir_p "application/android/assets/bin"
      FileUtils.mkdir_p "application/android/assets/libs"
      
      sh "xcopy /Y /I sdk\\bin\\*.loom application\\android\\assets\\bin"
      sh "xcopy /Y /I sdk\\assets\\*.* application\\android\\assets\\assets"

      # TODO: LOOM-1070 can we build for release or does this have signing issues?
      Dir.chdir("application/android") do
        sh "ant.bat #{$targetAndroidBuildType}"
      end
      
      # Copy APKs to artifacts.
      FileUtils.mkdir_p "artifacts/android"
      sh "echo f | xcopy /F /Y application\\android\\bin\\#{$targetAPKName} #{$OUTPUT_DIRECTORY}\\android\\LoomDemo.apk"
      
      FileUtils.cp_r("tools/apktool/apktool.jar", "artifacts/")
    else
      # OSX / LINUX
      FileUtils.mkdir_p("cmake_android")
      Dir.chdir("cmake_android") do
        sh "cmake -DCMAKE_TOOLCHAIN_FILE=../build/cmake/loom.android.toolchain.cmake #{$buildDebugDefine} -DANDROID_ABI=armeabi-v7a  -DLOOM_BUILD_JIT=#{$doBuildJIT} -DANDROID_NATIVE_API_LEVEL=14 -DCMAKE_BUILD_TYPE=#{$buildTarget} .."
        sh "make -j#{$numCores}"
      end
      
      api_id = get_android_api_id($targetAndroidSDK)

      Dir.chdir("loom/engine/cocos2dx/platform/android/java") do
        puts "*** Building against AndroidSDK " + $targetAndroidSDK
        sh "android update project --name Cocos2DLib --subprojects --target #{api_id} --path ."
      end
      
      Dir.chdir("application/android") do
        puts "*** Building against AndroidSDK " + $targetAndroidSDK
        sh "android update project --name LoomDemo --subprojects --target #{api_id} --path ."
      end
      
      FileUtils.mkdir_p "application/android/assets"
      FileUtils.mkdir_p "application/android/assets/assets"
      FileUtils.mkdir_p "application/android/assets/bin"
      FileUtils.mkdir_p "application/android/assets/libs"
      
      sh "cp sdk/bin/*.loom application/android/assets/bin"
      sh "cp sdk/assets/*.* application/android/assets/assets"
      
      # TODO: LOOM-1070 can we build for release or does this have signing issues?
      Dir.chdir("application/android") do
        sh "ant #{$targetAndroidBuildType}"
      end
      
      # Copy APKs to artifacts.
      FileUtils.mkdir_p "artifacts/android"
      sh "cp application/android/bin/#{$targetAPKName} #{$OUTPUT_DIRECTORY}/android/LoomDemo.apk"

      FileUtils.cp_r("tools/apktool/apktool.jar", "artifacts/")
    end
  end

  desc "Builds OUYA APK" #TODO: add Ouya build scripts under windows
  task :ouya => ['build:android'] do

    # Ouya build is currently not supported under Windows
    if $LOOM_HOST_OS != 'windows'
      puts "== Building OUYA =="

      ouyaAndroidSDK = "android-16"
          
      Dir.chdir("application/ouya") do
        puts "*** Building against AndroidSDK " + ouyaAndroidSDK
        api_id = get_android_api_id(ouyaAndroidSDK)
        sh "android update project --name LoomDemo --subprojects --target #{api_id} --path ."
      end

      FileUtils.mkdir_p "application/ouya/assets"
      FileUtils.mkdir_p "application/ouya/assets/assets"
      FileUtils.mkdir_p "application/ouya/assets/bin"
      FileUtils.mkdir_p "application/ouya/assets/libs"

      FileUtils.mkdir_p "application/ouya/libs/armeabi-v7a"

      sh "cp application/android/libs/armeabi-v7a/* application/ouya/libs/armeabi-v7a"
      
      sh "cp sdk/bin/*.loom application/ouya/assets/bin"
      sh "cp sdk/assets/*.* application/ouya/assets/assets"
      
      # TODO: LOOM-1070 can we build for release or does this have signing issues?
      Dir.chdir("application/ouya") do
        sh "ant #{$targetAndroidBuildType}"
      end

      # Copy APKs to artifacts.
      FileUtils.mkdir_p "artifacts/ouya"
      sh "cp application/ouya/bin/#{$targetAPKName} #{$OUTPUT_DIRECTORY}/ouya/LoomDemo.apk"

      FileUtils.cp_r("tools/apktool/apktool.jar", "artifacts/")
    end
  end

  desc "Builds Ubuntu Linux"
  task :ubuntu => ['build/luajit_x86/lib/libluajit-5.1.a'] do
    puts "== Building Ubuntu =="
    FileUtils.mkdir_p("cmake_ubuntu")    
    Dir.chdir("cmake_ubuntu") do
      sh "cmake ../ -DLOOM_BUILD_JIT=#{$doBuildJIT} -G \"Unix Makefiles\" -DCMAKE_BUILD_TYPE=#{$buildTarget} #{$buildDebugDefine}"
      sh "make -j#{$numCores}"
    end
    
    Rake::Task["utility:compileScripts"].invoke

    # build ldb
    Dir.chdir("sdk") do
      sh "../artifacts/lsc LDB.build"
    end

    # copy libs
    FileUtils.cp_r("sdk/libs", "artifacts/")
    FileUtils.cp_r("sdk/bin/LDB.loom", "artifacts")

    puts "Copying to #{$OUTPUT_DIRECTORY}/ubuntu"
    
    FileUtils.cp_r('./sdk/bin', './artifacts/ubuntu')
    FileUtils.cp_r('./sdk/assets', './artifacts/ubuntu')

    # copy asset agent
    FileUtils.cp("cmake_ubuntu/tools/assetAgent/libassetAgent.so", "artifacts/libassetAgent.so")
    
    #copy assets
    FileUtils.mkdir_p("artifacts/assets")

  end
  
  desc "Populate git version information"
  task :get_git_details do
    git_rev_long = `git rev-parse HEAD`
    git_rev_short = `git rev-parse --short HEAD`

    puts "Long: #{git_rev_long}"
    puts "Short: #{git_rev_short}"
  end

end

task :list_targets do
  puts "Listing all rake targets:"
  system("rake -T")
end

file 'build/luajit_x86/lib/libluajit-5.1.a' do 
    rootFolder = Dir.pwd 
    lua_jit_dir = File.join(rootFolder, "build", "luajit_x86")
    puts "building LuaJIT x86"
    Dir.chdir("loom/vendor/luajit") do
      sh "make clean"

      if $LOOM_HOST_OS == 'darwin'
        sh "make buildOSX PREFIX\"=#{lua_jit_dir.shellescape}\" -j#{$numCores}"
      else
        sh "make CC=\"gcc -m32\" PREFIX\"=#{lua_jit_dir.shellescape}\" -j#{$numCores}"
      end
      
      sh "make CC=\"gcc -m32\" install PREFIX=\"#{lua_jit_dir.shellescape}\""
    end
end  

file 'build/luajit_android/lib/libluajit-5.1.a' do 

    if $LOOM_HOST_OS == "windows"

      puts "installing LuaJIT Android on Windows"
      FileUtils.cp_r("loom/vendor/luajit_windows_android/luajit_android", "build")
      
      #TODO: LOOM-1634 https://theengineco.atlassian.net/browse/LOOM-1634
      #LuaJIT android build on Windows is currently extremely problematic.  It does build with dwimperl gcc in path, however building from
      #vanilla NDK does not work due to a combination of NDK make/gcc and magic flags.  In the meantime, we use this prebuilt LuaJIT android
      #build which the Rakefile copies into the proper location instead of building Android luaJIT on Windows
      
      #puts "building LuaJIT Android on Windows"
      #NDK = "#{ENV['ANDROID_NDK']}"
      #if (!NDK or NDK == "")
      #    raise "\n\nPlease ensure ANDROID_NDK environment variable is set to your NDK path\n\n"
      #end
      #rootFolder = Dir.pwd
      #luajit_android_dir = File.join(rootFolder, "build", "luajit_android")
      #Dir.chdir("loom/vendor/luajit") do
      #    sh "#{NDK}\\prebuilt\\#{WINDOWS_ANDROID_PREBUILT_DIR}\\bin\\make -f Makefile.win32 clean"
      #    ENV['NDKABI']= "9" 
      #    ENV['NDKVER']= NDK + "\\toolchains\\arm-linux-androideabi-4.6"
      #    ENV['NDKP'] = ENV['NDKVER'] + "\\prebuilt\\#{WINDOWS_ANDROID_PREBUILT_DIR}\\bin\\arm-linux-androideabi-"
      #    ENV['NDKF'] = "--sysroot " + NDK + "\\platforms\\android-" + ENV['NDKABI'] + "\\arch-arm"
      #    sh "#{NDK}\\prebuilt\\#{WINDOWS_ANDROID_PREBUILT_DIR}\\bin\\make -f Makefile.win32 install -j#{$numCores} HOST_CC=\"gcc -m32\" CROSS=" + ENV['NDKP'] + " TARGET_FLAGS=\"" + ENV['NDKF']+"\" TARGET=arm TARGET_SYS=Linux PREFIX=\"#{luajit_android_dir.shellescape}\""
      #end
    else
    puts "building LuaJIT Android on OSX / Linux"
      # OSX / LINUX
      NDK = ENV['ANDROID_NDK']
      if (!NDK)
          raise "\n\nPlease ensure ndk-build from NDK rev 8b is on your path"
      end
      rootFolder = Dir.pwd
      luajit_android_dir = File.join(rootFolder, "build", "luajit_android")
      Dir.chdir("loom/vendor/luajit") do
          sh "make clean"
          ENV['NDKABI']= "9" 
          ENV['NDKVER']= NDK + "/toolchains/arm-linux-androideabi-4.6"
          ENV['NDKP'] = ENV['NDKVER'] + "/prebuilt/darwin-x86/bin/arm-linux-androideabi-"
          ENV['NDKF'] = "--sysroot " + NDK + "/platforms/android-" + ENV['NDKABI'] + "/arch-arm"
          sh "make install -j#{$numCores} HOST_CC=\"gcc -m32\" CROSS=" + ENV['NDKP'] + " TARGET_FLAGS=\"" + ENV['NDKF']+"\" TARGET=arm TARGET_SYS=Linux PREFIX=\"#{luajit_android_dir.shellescape}\""
      end
    end 
end

file 'build/luajit_ios/lib/libluajit-5.1.a' do 

  if $LOOM_HOST_OS != "windows"
    puts "building LuaJIT iOS"

    check_ios_sdk_version! $targetIOSSDK
    
    ISDK="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer"
    ISDKVER="iPhoneOS#{$targetIOSSDK}.sdk"
    ISDKP=ISDK + "/usr/bin/"
    ISDKF="-arch armv7 -isysroot " + ISDK + "/SDKs/" + ISDKVER
    
    ENV['ISDK'] = ISDK
    ENV['ISDKVER'] = ISDKVER
    ENV['ISDKP'] = ISDKP
    ENV['ISDKF'] = ISDKF
    
    rootFolder = Dir.pwd
    luajit_ios_dir = File.join(rootFolder, "build", "luajit_ios")
    Dir.chdir("loom/vendor/luajit") do
        sh "make clean"
        if $targetIOSSDK >= "7.0"
              sh "make install -j#{$numCores} HOST_CC=\"gcc -m32 -arch i386\" TARGET_FLAGS=\"" + ISDKF + "\" TARGET=arm TARGET_SYS=iOS PREFIX=\"#{luajit_ios_dir.shellescape}\""
        else
              sh "make install -j#{$numCores} HOST_CC=\"gcc -m32 -arch i386\" CROSS=" + ISDKP + " TARGET_FLAGS=\"" + ISDKF + "\" TARGET=arm TARGET_SYS=iOS PREFIX=\"#{luajit_ios_dir.shellescape}\""
        end            
    end
  end
end

file 'build\luajit_windows\lua51.lib' do 

    puts "building LuaJIT Win32"
    
    Dir.chdir("loom/vendor/luajit/src") do
        sh "msvcbuild.bat release static"
    end

end

# FIXME: At some point test should just run the tests and not try to build OSX
# mainly we need to make windows work
desc "Runs all unit tests and exports results to artifacts/testResults.xml"
task :test => ['build:desktop'] do
   Dir.chdir("sdk") do
      sh "../artifacts/lsc --unittest --xmlfile ../artifacts/testResults.xml"
  end
end

namespace :deploy do

  desc "Deploy sdk locally"
  task :sdk, [:sdk_version] => ['package:sdk'] do |t, args|
    args.with_defaults(:sdk_version => "dev")
    sdk_path = File.join("#{ENV['HOME']}/.loom", "sdks", args[:sdk_version])

    # Remove the previous version
    FileUtils.rm_rf sdk_path if File.directory? sdk_path
    unzip_file("pkg/loomsdk.zip", sdk_path)

    puts "Installing sdk locally for loomcli under the name #{args[:sdk_version]}"
  end

  desc "Deploy the free version of the sdk locally"
  task :free_sdk, [:sdk_version] => ['package:free_sdk'] do |t, args|
    args.with_defaults(:sdk_version => "dev")
    sdk_path = File.join("#{ENV['HOME']}/.loom", "sdks", args[:sdk_version])

    # Remove the previous version
    FileUtils.rm_rf sdk_path if File.directory? sdk_path
    unzip_file("pkg/loomsdk.zip", sdk_path)

    puts "Installing sdk locally for loomcli under the name #{args[:sdk_version]}"
  end

  desc "Deploy debug build to android."
  task :android do
    Dir.chdir("application/android") do
      if $targetAndroidBuildType == "debug"
        sh "ant installd"
      elsif $targetAndroidBuildType == "release"
        sh "ant installr"
      else
        abort("Unknown android build type #{$targetAndroidBuildType}, update deploy:android task to know about new type.")
      end
    end
  end

end

namespace :update do
  desc "Updates the scripts in an already deployed sdk."
  task :sdk, [:sdk_version] do |t, args|
    args.with_defaults(:sdk_version => "dev")
    sdk = args[:sdk_version]
    sdk_path = File.join("#{ENV['HOME']}/.loom", "sdks", sdk)

    if !File.exists?(sdk_path)
      abort("SDK #{sdk} does not exist! Please run `rake deploy:sdk[#{sdk}]` to build it.")
    end

    puts "===== Compiling Core Scripts ====="
    Dir.chdir("sdk") do
      sh "../artifacts/lsc Main.build"
    end

    FileUtils.cp_r("sdk/libs", sdk_path);

    puts "Updated sdk locally for loomcli under the name #{sdk}"
  end
end

namespace :package do

  desc "Package Native SDK"
  task :nativesdk do
    puts "== Packaging Native SDK =="

    FileUtils.rm_rf "nativesdk.zip"

    omit_files = %w[ examples.zip loomsdk.zip certs/LoomDemoBuild.mobileprovision loom/vendor/telemetry-01052012 pkg/ artifacts/ docs/output cmake_osx/ cmake_msvc/ cmake_ios/ cmake_android/]

    require 'zip/zip'
    Zip::ZipFile.open("nativesdk.zip", 'w') do |zipfile|
      Dir["**/**"].each do |file|
        
        do_omit = false
        omit_files.each do |omitted|
          if file.include? omitted
            puts "Omitted #{file}"
            do_omit = true
          end
        end

        unless do_omit
          puts "Adding #{file}"
          zipfile.add(file, file)
        end
      end
    end

    puts "== Native SDK Packaged =="
  end

  desc "Package examples to pkg/examples.zip"
  task :examples do
    puts "== Packaging Examples =="

    FileUtils.rm_rf "pkg/examples.zip"
    FileUtils.mkdir_p "pkg"

    require 'zip/zip'
    Zip::ZipFile.open("pkg/examples.zip", 'w') do |zipfile|
      Dir["docs/examples/**/**"].each do |file|
        zipfile.add(file.sub("docs/examples/", ''),file)
      end
    end

    puts "== Examples Packaged =="
  end

  desc "Packages SDK"
  task :sdk => ['build:all', "generate:docs"] do
    puts "== Packaging Loom SDK =="

    prepare_free_sdk

    FileUtils.rm_rf "pkg/sdk/bin/android"

    # iOS and Ouya are currently not supported under Windows
    if $LOOM_HOST_OS != "windows"
      # copy tools
      FileUtils.cp_r("artifacts/fruitstrap", "pkg/sdk/tools")

      # ============================================================= iOS
      # put together a folder to zip up
      FileUtils.mkdir_p "pkg/sdk/bin/ios"
      
      # add the ios app bundle
      FileUtils.cp_r("artifacts/ios/LoomDemo.app", "pkg/sdk/bin/ios")
      
      # Strip out the bundled assets and binaries
      FileUtils.rm_rf "pkg/sdk/bin/ios/LoomDemo.app/assets"
      FileUtils.rm_rf "pkg/sdk/bin/ios/LoomDemo.app/bin"
      FileUtils.rm_rf "pkg/sdk/bin/ios/LoomDemo.app/libs"

      # ============================================================= Ouya
      # decompile the ouya apk
      decompile_apk("application/ouya/bin/#{$targetAPKName}","pkg/sdk/bin/ouya")
      
      # Strip out the bundled assets and binaries
      FileUtils.rm_rf "pkg/sdk/bin/ouya/assets/assets"
      FileUtils.rm_rf "pkg/sdk/bin/ouya/assets/bin"
      FileUtils.rm_rf "pkg/sdk/bin/ouya/assets/libs"
      FileUtils.rm_rf "pkg/sdk/bin/ouya/META-INF"

    end

    FileUtils.cp_r("artifacts/apktool.jar", "pkg/sdk/tools")

    # ============================================================= Android
    # decompile the android apk
    FileUtils.mkdir_p "pkg/sdk/bin/android"
    decompile_apk("application/android/bin/#{$targetAPKName}","pkg/sdk/bin/android")

    # Strip out the bundled assets and binaries
    FileUtils.rm_rf "pkg/sdk/bin/android/assets/assets"
    FileUtils.rm_rf "pkg/sdk/bin/android/assets/bin"
    FileUtils.rm_rf "pkg/sdk/bin/android/assets/libs"
    FileUtils.rm_rf "pkg/sdk/bin/android/META-INF"

    if $LOOM_HOST_OS == 'windows'
      # Under windows copy the .so file over
      sh "if not exist pkg\\sdk\\bin\\android\\lib mkdir pkg\\sdk\\bin\\android\\lib"
      sh "for /d %F in (libs\\*.*) do xcopy /Y /I /E /F %F\\*.so pkg\\sdk\\bin\\android\\lib\\%~nF"
    end

    require_dependencies

    puts "Compressing Loom SDK..."
    Zip::ZipFile.open("pkg/loomsdk.zip", 'w') do |zipfile|
      Dir["pkg/sdk/**/**"].each do |file|
        zipfile.add(file.sub("pkg/sdk/", ''),file)
      end
    end
    FileUtils.rm_rf "pkg/sdk"
    puts "Packaged to pkg/loomsdk.zip"
    
  end

  desc "Packages the free version of the SDK"
  task :free_sdk => ['build:desktop', "generate:docs"] do
    puts "== Packaging Free Loom SDK =="

    prepare_free_sdk

    require_dependencies

    FileUtils.mkdir_p "pkg"

    Zip::ZipFile.open("pkg/loomsdk.zip", 'w') do |zipfile|
      Dir["pkg/sdk/**/**"].each do |file|
        zipfile.add(file.sub("pkg/sdk/", ''),file)
      end
    end

    FileUtils.rm_rf "pkg/sdk"
    puts "Packaged to pkg/loomsdk.zip"
    
  end

end

def decompile_apk (file, destination)
  puts "Decompiling APK #{file} to #{destination}..."
  sh "java -jar tools/apktool/apktool.jar d -f #{file} #{destination}"
end

def require_dependencies
  begin
    require 'rubygems'
    require 'zip/zip'
    require 'zip/zipfilesystem'
  rescue LoadError
    puts "This Rakefile requires the rubyzip gem. Install it using: gem install rubyzip"
    exit(1)
  end
end

def unzip_file (file, destination)
  require_dependencies

  Zip::ZipFile.open(file) do |zip_file|
    zip_file.each do |f|
      f_path=File.join(destination, f.name)
      FileUtils.mkdir_p(File.dirname(f_path))
      zip_file.extract(f, f_path) unless File.exist?(f_path)
    end
  end
end

def get_app_prefix (appPath)
  # Find the .app in the artifacts folder.
  puts "Application path found: #{appPath}"
  appNameMatch = /\/(\w*\.app)$/.match(appPath)
  appName = appNameMatch[0]
  puts "Application name found: #{appName}"
  appPrefix = appName.split(".")[0]
  puts "Application prefix is: #{appPrefix}"

    return appPrefix
end

desc "Build the Free SDK (desktop only)"
def prepare_free_sdk
  FileUtils.rm_rf "sdk/LoomDemo.app"
  FileUtils.rm_rf "sdk/LoomDemo.exe"
  FileUtils.rm_rf "pkg"


  # put together a folder to zip up
  FileUtils.mkdir_p "pkg/sdk"
  FileUtils.mkdir_p "pkg/sdk/bin"
  FileUtils.mkdir_p "pkg/sdk/tools"
  FileUtils.mkdir_p "pkg/sdk/libs"
  FileUtils.mkdir_p "pkg/sdk/assets"
  FileUtils.mkdir_p "pkg/sdk/src"

  #copy the docs in
  FileUtils.cp_r("artifacts/docs","pkg/sdk") if File.exists? "artifacts/docs"
  
  #copy the minimum cli version
  FileUtils.cp("MIN_CLI_VERSION", "pkg/sdk")

  # copy the libs
  FileUtils.cp_r("artifacts/libs", "pkg/sdk")

  if($LOOM_HOST_OS == "windows")

    FileUtils.cp_r("artifacts/windows/LoomDemo.exe", "pkg/sdk/bin")

    # copy tools
    FileUtils.cp_r("artifacts/lsc.exe", "pkg/sdk/tools")
    FileUtils.cp_r("artifacts/loomexec.exe", "pkg/sdk/tools")
    FileUtils.cp_r("artifacts/assetAgent.dll", "pkg/sdk/tools")
    FileUtils.cp_r("artifacts/ldb.exe", "pkg/sdk/tools")
  elsif $LOOM_HOST_OS == "linux"
    FileUtils.cp_r("artifacts/ubuntu/LoomDemo", "pkg/sdk/bin/LoomDemo.ubuntu")

    # copy tools
    FileUtils.cp_r("artifacts/lsc", "pkg/sdk/tools/lsc.ubuntu")
    FileUtils.cp_r("artifacts/loomexec", "pkg/sdk/tools/loomexec.ubuntu")
    FileUtils.cp_r("artifacts/libassetAgent.so", "pkg/sdk/tools/libassetAgent.ubuntu.so")
    FileUtils.cp_r("artifacts/ldb", "pkg/sdk/tools/ldb.ubuntu")
  else

    # copy the bin
    FileUtils.cp_r("artifacts/osx/LoomDemo.app", "pkg/sdk/bin")

    # Strip out the bundled assets and binaries
    FileUtils.rm_rf "pkg/sdk/bin/LoomDemo.app/Contents/Resources/assets"
    FileUtils.rm_rf "pkg/sdk/bin/LoomDemo.app/Contents/Resources/bin"
    FileUtils.rm_rf "pkg/sdk/bin/LoomDemo.app/Contents/Resources/libs"

    # copy tools
    FileUtils.cp_r("artifacts/lsc", "pkg/sdk/tools")
    FileUtils.cp_r("artifacts/loomexec", "pkg/sdk/tools")
    FileUtils.cp_r("artifacts/libassetAgent.so", "pkg/sdk/tools")
    FileUtils.cp_r("artifacts/ldb", "pkg/sdk/tools")

  end

  # copy ldb
  FileUtils.cp_r("artifacts/LDB.loom", "pkg/sdk/bin")

  # copy the assets we need from cocos...
  FileUtils.cp_r("artifacts/assets", "pkg/sdk")

  require_dependencies
end

def has_ios_sdk(version)
    #kinda hacky, lookup clang
    system "xcrun --sdk iphoneos#{version} --find clang &> /dev/null"
end

def check_ios_sdk_version!(version)
  # XCode version check
  if ! has_ios_sdk(version)
    abort("iOS SDK version #{version} is not installed. Please adjust the settings in Rakefile if you have a different version installed or set the environment variable IOS_SDK.")
  end
end

def get_android_api_id(api_name)

  if $LOOM_HOST_OS == "windows"
    grep = "findstr"
  else
    grep = "grep"
  end

  api_id = `android list target | #{grep} "#{api_name}"`

  if api_id.empty?
    puts "===================================================================="
    puts " ERROR :: Unable to find android SDK '#{api_name}', is it installed?"
    puts "===================================================================="
    exit(1)
  else
    api_id = api_id.split(" ")[1]
  end
end
