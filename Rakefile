###############################
# MODULES
###############################

require 'rubygems'
require 'rbconfig'
include RbConfig

path = File.expand_path(File.join(File.dirname(__FILE__), 'build', 'libs'))
$LOAD_PATH << path

require 'host'
require 'toolchains'
require 'targets'
require 'helper'
require 'ios_helper'
require 'android_helper'

require 'rake/clean'
require 'rake/packagetask'
require 'pathname'
require 'shellwords'

require 'zip'
require 'zip/file'

load "./build/Swarley"

###############################
# BUILD CONFIGURATION VARIABLES
###############################

CFG =
{
    # Specify the build target - Debug, Release, RelMinSize, RelWithDebug
    BUILD_TARGET: "Release",

    # the sdk_version name that will be generated when this sdk is deployed (default = "dev")
    TARGET_SDK_VER: "dev",

    # What version of the android SDK are going to target? Note you also need to update the Android project and manifest to match.
    TARGET_ANDROID_SDK: "android-13" ,

    # What Android target are we going to build? debug and release are the main
    # options but there are more. (see http://developer.android.com/tools/building/building-cmdline.html)
    TARGET_ANDROID_BUILD_TYPE: "release", # "debug"

    # What version of iOS SDK are we going to build for? If you set IOS_SDK in your
    # environment, it will override.
    TARGET_IOS_SDK: if ENV['IOS_SDK'] then ENV['IOS_SDK'] else "6.0" end,

    # If 1, then we link against LuaJIT. If 0, we use classic Lua VM.
    USE_LUA_JIT: 1,

    # If 1, then LUA GC profiling code is enabled
    ENABLE_LUA_GC_PROFILE: 1,

    # Whether or not to include Admob and/or Facebook in the build... for Great Apple Compliance!
    BUILD_ADMOB: 0,
    BUILD_FACEBOOK: 0,

    # Allow disabling Loom doc generation, as it can be very slow.
    # Disabled by default, set environment variable 'LOOM_BUILD_DOCS'
    BUILD_DOCS: ENV['LOOM_BUILD_DOCS'] == "1" || ENV['LOOM_BUILD_DOCS'] == "true",

    # Loom SDK version
    LOOM_VERSION: File.new("VERSION").read.chomp,
}

###############################
# GLOBALS
###############################

$ROOT = Dir.pwd
$HOST = Host::create()
$OUTPUT_DIRECTORY = "artifacts"
$HOST_ARTIFACTS = "#{$ROOT}/artifacts/#{$HOST.name}-#{$HOST.arch}"
if $LOOM_HOST_OS == 'windows'
  $LSC_BINARY = "#{$HOST_ARTIFACTS}\\tools\\lsc.exe"
else
  $LSC_BINARY = "#{$HOST_ARTIFACTS}/tools/lsc"
end

if $HOST.name == 'windows'
  $LOOM_BINARY = "#{$HOST_ARTIFACTS}/bin/LoomDemo.exe"
elsif $HOST.name == 'osx'
  $LOOM_BINARY = "#{$HOST_ARTIFACTS}/bin/LoomDemo.app/Contents/MacOS/LoomDemo"
else
  $LOOM_BINARY = "#{$HOST_ARTIFACTS}/bin/LoomDemo"
end

###############################
# INIT
###############################

check_versions

# Report build configuration values
puts "== Executing as '#{ENV['USER']}' =="
puts ""
puts "LoomSDK (#{CFG[:LOOM_VERSION]}) Rakefile running on Ruby v#{RUBY_VERSION}"
puts "  CMake version: #{$CMAKE_VERSION}"
puts "  Build type: #{CFG[:BUILD_TARGET]}"
puts "  Using JIT? #{CFG[:USE_LUA_JIT]} | Building AdMob? #{CFG[:BUILD_ADMOB]} | Building FacebookSDK? #{CFG[:BUILD_FACEBOOK]}"
puts "  Detected #{$HOST.name} on arch #{$HOST.arch}"
puts "  Building with #{$HOST.num_cores} cores."
puts "  AndroidSDK: #{CFG[:TARGET_ANDROID_SDK]} | AndroidBuildType: #{CFG[:TARGET_ANDROID_BUILD_TYPE]} | Target APK: #{AndroidToolchain::apkName}"
puts "  iOS SDK version: #{CFG[:TARGET_IOS_SDK]}"
puts "  Building Loom docs? #{CFG[:BUILD_DOCS]}"
puts ""

#############
# BUILD TASKS
#############

# Don't use clean defaults, they will nuke things we don't want!
CLEAN.replace(["application/android/bin" ])
CLEAN.include Dir.glob("build/loom-*")
CLEAN.include Dir.glob("build/luajit-*")
CLEAN.include Dir.glob("tests/unittest-*")
CLEAN.include ["build/**/lib/**", "artifacts/**"]
CLOBBER.include ["**/*.loom", $OUTPUT_DIRECTORY]
CLOBBER.include ["**/*.loomlib", $OUTPUT_DIRECTORY]

Rake::TaskManager.record_task_metadata = true # this must be outside default task and before all tasks
task :list_targets do
  Rake.application.options.show_tasks = :tasks
  Rake.application.options.show_task_pattern = //
  Rake.application.display_tasks_and_comments()
end

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
    response = STDIN.gets
    if response.chomp! == "yes" || response.chomp! == "y"
      sh "git clean -fdx"
    else
      puts "Phew, that was close!"
    end
  end
end

namespace :generate do

  desc "Generates API docs for the loomscript sdk"
  task :docs => ['build:desktop'] do

    if CFG[:BUILD_DOCS] || ARGV.include?('generate:docs')
      Dir.chdir("docs") do
        load "./main.rb"
      end

      # Nuke all the garbage in the examples folders.
      Dir.glob("docs/output/examples/*/") do |exampleFolder|
        FileUtils.rm_r "#{exampleFolder}/assets", :force => true
        FileUtils.rm_r "#{exampleFolder}/bin", :force => true
        FileUtils.rm_r "#{exampleFolder}/libs", :force => true
        FileUtils.rm_r "#{exampleFolder}/src", :force => true
      end

      # make sure we don't accumulate junk in the artifacs/docs folder.
      FileUtils.rm_r "artifacts/docs", :force => true
      FileUtils.mkdir_p "artifacts/docs"
      FileUtils.cp_r "docs/output/.", "artifacts/docs/"
    else
      puts "Skipping docs since LOOM_BUILD_DOCS is not set."
    end
  end

end

namespace :docs do

  $DOCS_INDEX = 'artifacts/docs/index.html'

  file $DOCS_INDEX do
    Rake::Task['docs:regen'].invoke
    puts " *** docs built!"
  end

  desc "Rebuilds loomlibs and docs"
  task :regen => "build:desktop" do
    puts "===== Recompiling loomlibs ====="
    Dir.chdir("sdk") do
      sh "#{$LSC_BINARY} Main.build"
    end
    cp_r_safe("sdk/libs", "artifacts/")

    puts "===== Recreating the docs ====="
    Dir.chdir("docs") do
      ENV['LOOM_VERSION'] = CFG[:LOOM_VERSION] unless ENV['LOOM_VERSION']
      load "./main.rb"
    end
    cp_r_safe "docs/output/.", "artifacts/docs/"
  end

  desc "Opens the current docs in a web browser"
  task :open => $DOCS_INDEX do
    $HOST.open "artifacts/docs/index.html"
  end

  desc "Rebuilds docs and opens in browser"
  task :refresh => ['docs:regen', 'docs:open']

end

namespace :utility do

  desc "Compile scripts and report any errors."
  task :compileScripts => "build:desktop" do
    puts "===== Compiling Core Scripts ====="
    FileUtils.mkdir_p("artifacts/libs")
    Dir.chdir("sdk") do
      sh "#{$LSC_BINARY} Main.build"
    end
    FileUtils.cp_r("sdk/libs", "#{$OUTPUT_DIRECTORY}")
    FileUtils.cp_r('sdk/bin', "#{$OUTPUT_DIRECTORY}/bin")
    FileUtils.cp_r('sdk/assets', "#{$OUTPUT_DIRECTORY}")
  end

  desc "Compile tools and report any errors."
  task :compileTools => "build:desktop" do
    puts "===== Compiling Core Scripts ====="
    FileUtils.mkdir_p("artifacts/libs")
    # build ldb
    Dir.chdir("sdk") do
      sh "#{$LSC_BINARY} LDB.build"
    end
    # build testexec
    Dir.chdir("sdk") do
      sh "#{$LSC_BINARY} TestExec.build"
    end
    FileUtils.cp_r("sdk/bin/LDB.loom", "#{$OUTPUT_DIRECTORY}/libs")
    FileUtils.cp_r("sdk/bin/TestExec.loom", "#{$OUTPUT_DIRECTORY}/libs")
    FileUtils.cp_r("sdk/src/testexec/loom.config", "#{$OUTPUT_DIRECTORY}/libs/TestExec.config")
  end

  desc "Compile demos and report any errors"
  task :compileDemos => "build:desktop" do

    Dir["docs/examples/*"].each do | demo |
      next unless File.directory? demo

      demoName = File.basename(demo)

      next if demoName == '.' or demoName == '..'

      Rake::Task['utility:compileDemo'].invoke(demoName)
      Rake::Task['utility:compileDemo'].reenable
    end

  end

  desc "Compile demo"
  task :compileDemo, [:name] => "build:desktop" do |t, args|
      puts "===== Compiling #{args[:name]} ====="
      Dir.chdir("docs/examples/#{args[:name]}") do
        sh "#{$LSC_BINARY}"
      end
      
      # Clean up the libs and bin folders to save tons of space.
      FileUtils.rm_r("docs/examples/#{args[:name]}/libs")
      FileUtils.rm_r("docs/examples/#{args[:name]}/bin")
  end

  desc "Run demo"
  task :runDemo, [:name] => "build:desktop" do |t, args|
    puts "===== Running #{args[:name]} ====="
    expandedArtifactsPath = File.expand_path($OUTPUT_DIRECTORY)
      
    Dir.chdir("docs/examples/#{args[:name]}") do
      sh "#{$LSC_BINARY}"
      sh "#{$LOOM_BINARY}"
    end
  end

  desc "Run the LoomDemo in artifacts"
  task :run => "build:desktop" do
    puts "===== Launching Application ====="

    Dir.chdir("artifacts") do
      sh "#{$LOOM_BINARY}"
    end
  end

  desc "Run app under GDB if available"
  task :debug => ['build:osx'] do
    puts "===== Launching Application ====="

    if !installed? "gdb"
      puts "GDB is not installed on your system"
      abort
    end

    Dir.chdir("artifacts") do
      sh "gdb #{$LOOM_DEMO}"
    end
  end

end

namespace :build do

  desc "Build Everything"
  task :all do
    puts "building all"
    Rake::Task["build:desktop"].invoke
    Rake::Task["build:android"].invoke
    if $HOST.name == 'osx'
		Rake::Task["build:ios"].invoke
    end
  end

  desc "Builds the native desktop platform (OSX or Windows)"
  task :desktop do
    if $HOST.name == 'windows'
      Rake::Task["build:windows"].invoke
    elsif $HOST.name == 'osx'
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
    cp_r_safe("tools/fruitstrap/fruitstrap", "#{$OUTPUT_DIRECTORY}/ios-arm/")
  end

  desc "Builds OS X"
  task :osx => [] do

    if $HOST.name != 'osx'
      return
    end

    puts "== Building OS X =="

    toolchain = OSXToolchain.new();
    luajit_x86 = LuaJITTarget.new(0);
    loom_x86 = LoomTarget.new(0, luajit_x86);
    if CFG[:USE_LUA_JIT] == 1 then
      toolchain.build(luajit_x86)
    end
    toolchain.build(loom_x86)

    if $HOST.is_x64 == '1' then
      luajit_x64 = LuaJITTarget.new(1);
      loom_x64 = LoomTarget.new(1, luajit_x64);
      if CFG[:USE_LUA_JIT] == 1 then
        toolchain.build(luajit_x64)
      end
      toolchain.build(loom_x64)
    end

    Rake::Task["utility:compileScripts"].invoke
    Rake::Task["utility:compileTools"].invoke
  end

  desc "Builds iOS"
  task :ios, [:sign_as] => ['utility:compileScripts', 'build:fruitstrap'] do |t, args|

    sh "touch #{$OUTPUT_DIRECTORY}/ios-arm/fruitstrap"
    sh "mkdir -p #{$OUTPUT_DIRECTORY}/ios-arm/LoomDemo.app"
    sh "mkdir -p #{$OUTPUT_DIRECTORY}/ios-arm/LoomDemo.app/assets"
    sh "touch #{$OUTPUT_DIRECTORY}/ios-arm/LoomDemo.app/assets/tmp"
    sh "mkdir -p #{$OUTPUT_DIRECTORY}/ios-arm/LoomDemo.app/bin"
    sh "touch #{$OUTPUT_DIRECTORY}/ios-arm/LoomDemo.app/bin/tmp"
    sh "mkdir -p #{$OUTPUT_DIRECTORY}/ios-arm/LoomDemo.app/lib"
    sh "touch #{$OUTPUT_DIRECTORY}/ios-arm/LoomDemo.app/lib/tmp"

    
    # iOS build is currently not supported under Windows
    if $HOST.name != 'windows'
      puts "== Building iOS =="

      check_ios_sdk_version! CFG[:TARGET_IOS_SDK]

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
        puts "**********************************************"
        puts "WARNING: Using default iOS signing identity. Set IOS_SIGNING_IDENTITY to control the identity used."
        puts "**********************************************"
        args.with_defaults(:sign_as => "iPhone Developer")
      end
      puts "*** Signing Identity = #{args.sign_as}"

      $ROOTFolder = Dir.pwd
      luajit_ios_dir = File.join($ROOTFolder, "build", "luajit-ios") 

      ISDK = "/Applications/XCode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer"
      ISDKVER = "iPhoneOS#{CFG[:TARGET_IOS_SDK]}.sdk"
      ISDKP = ISDK + "/usr/bin/"
      ISDKF = "-arch armv7 -isys$ROOT #{ISDK}/SDKs/#{ISDKVER}"

      ENV["ISDK"] = ISDK
      ENV["ISDKVER"] = ISDKVER
      ENV["ISDKP"] = ISDKP
      ENV["ISDKF"] = ISDKF

      FileUtils.mkdir_p("#{$ROOT}/build/loom-ios-arm")

      # Build SDL for iOS if it's missing
      sdlLibPath = "build/sdl2/ios/"
      if not File.exist?("#{sdlLibPath}/libSDL2.a")
        puts "Building SDL2 for iOS using xcodebuild"
        sdlProjPath = "loom/vendor/sdl2/Xcode-iOS/SDL/"
        Dir.chdir(sdlProjPath) do
          sh "xcodebuild" 
        end
        FileUtils.mkdir_p sdlLibPath
        sh "cp #{sdlProjPath}/build/Release-iphoneos/libSDL2.a #{sdlLibPath}/libSDL2.a"
      else
        puts "Found SDL2 libSDL2.a in #{sdlLibPath} - skipping build"
      end

      hostToolchain = OSXToolchain.new()
      toolchain = IOSToolchain.new(args.sign_as)
      luajit_bootstrap = LuaJITBootstrapTarget.new(0, toolchain)
      luajit_lib = LuaJITLibTarget.new(0, luajit_bootstrap)
      loom_arm = LoomTarget.new(0, luajit_lib)
      if CFG[:USE_LUA_JIT] == 1 then
        hostToolchain.build(luajit_bootstrap)
        toolchain.build(luajit_lib)
      end
      toolchain.build(loom_arm)
      # TODO When we clean this up... we should have get_app_prefix return and object with, appPath,
      # appNameMatch, appName and appPrefix

      # Find the .app in the build folder.
      appPath = Dir.glob("#{$ROOT}/build/loom-ios-arm/application/#{CFG[:BUILD_TARGET]}-iphoneos/*.app")[0]
      puts "Application path found: #{appPath}"
      appNameMatch = /\/(\w*\.app)$/.match(appPath)
      appName = appNameMatch[0]
      puts "Application name found: #{appName}"

      # Use fruitstrap's plist.
      sh "cp tools/fruitstrap/ResourceRules.plist #{appPath}/ResourceRules.plist"

      # Make it ito an IPA!
      full_output_path = Pathname.new("#{$OUTPUT_DIRECTORY}/ios-arm").realpath
      package_command = "/usr/bin/xcrun -sdk iphoneos PackageApplication"
      package_command += " -v '#{appPath}'"
      package_command += " -o '#{full_output_path}/#{appName}.ipa'"
      package_command += " --sign '#{args.sign_as}'"
      package_command += " --embed '#{$iosProvision}'"
      sh package_command

      # if Debug build, copy over the dSYM too
      if CFG[:BUILD_TARGET] == "Debug"
        dsymPath = Dir.glob("#{$ROOT}/build/loom-ios-arm/application/#{CFG[:BUILD_TARGET]}-iphoneos/*.dSYM")[0]
        puts "dSYM path found: #{dsymPath}"
        FileUtils.cp_r(dsymPath, full_output_path)
      end
    end
  end

  desc "Builds Windows"
  task :windows => [] do
    puts "== Building Windows =="
    toolchain = WindowsToolchain.new();
    luajit_x86 = LuaJITTarget.new(0);
    loom_x86 = LoomTarget.new(0, luajit_x86);
    if CFG[:USE_LUA_JIT] == 1 then
      toolchain.build(luajit_x86)
    end
    toolchain.build(loom_x86)

    if $HOST.is_x64 == '1' then
      luajit_x64 = LuaJITTarget.new(1);
      loom_x64 = LoomTarget.new(1, luajit_x64);
      if CFG[:USE_LUA_JIT] == 1 then
        toolchain.build(luajit_x64)
      end
      toolchain.build(loom_x64)
    end

    Rake::Task["utility:compileScripts"].invoke
    Rake::Task["utility:compileTools"].invoke
  end

  desc "Builds Android APK"
  task :android => ['utility:compileScripts'] do
    puts "== Building Android =="

    # Build SDL for Android if it's missing
    sdlLibPath = "build/sdl2/android/armeabi"
    if not File.exist?("#{sdlLibPath}/libSDL2.a")
      puts "Building SDL2 for Android using ndk-build"
      sdlSrcPath = "loom/vendor/sdl2"
      Dir.chdir(sdlSrcPath) do
        sh "ndk-build SDL2_static NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android.mk APP_PLATFORM=android-13" 
      end
      FileUtils.mkdir_p sdlLibPath
      sh "cp #{sdlSrcPath}/obj/local/armeabi/libSDL2.a #{sdlLibPath}/libSDL2.a"
    else
      puts "Found SDL2 libSDL2.a in #{sdlLibPath} - skipping build"
    end
	
    hostToolchain = $HOST.toolchain()
    toolchain = AndroidToolchain.new()
    luajit_bootstrap = LuaJITBootstrapTarget.new(0, toolchain)
    luajit_lib = LuaJITLibTarget.new(0, luajit_bootstrap)
    loom_arm = LoomTarget.new(0, luajit_lib)
    if CFG[:USE_LUA_JIT] == 1 then
      if $HOST.name != "windows"
        hostToolchain.build(luajit_bootstrap)
        toolchain.build(luajit_lib)
      else
        # Just copy over the prebuilt lib on windows, it's near impossible to build there
        FileUtils.mkdir_p luajit_lib.buildPath(toolchain)
        FileUtils.cp_r(Dir.glob("#{$ROOT}/loom/vendor/luajit_windows_android/luajit_android/lib/*"), luajit_lib.buildPath(toolchain))
      end
    end
    toolchain.build(loom_arm)

    puts "*** Building against AndroidSDK " + CFG[:TARGET_ANDROID_SDK]
    api_id = get_android_api_id(CFG[:TARGET_ANDROID_SDK])

    Dir.chdir("loom/vendor/facebook/android") do
      sh "android update project --name FacebookSDK --subprojects --target #{api_id} --path ."
    end

    Dir.chdir("loom/engine/sdl2/platform/android/java") do
      sh "android update project --name SDL2 --subprojects --target #{api_id} --path ."
    end

    Dir.chdir("application/android") do
      sh "android update project --name LoomDemo --subprojects --target #{api_id} --path ."
    end

    FileUtils.mkdir_p "application/android/assets"
    FileUtils.mkdir_p "application/android/assets/assets"
    FileUtils.mkdir_p "application/android/assets/bin"
    FileUtils.mkdir_p "application/android/assets/libs"

    FileUtils.cp_r(Dir.glob("sdk/bin/*.loom"), "application/android/assets/bin")
    FileUtils.cp_r(Dir.glob("sdk/assets/*.*"), "application/android/assets/assets")

      # TODO: LOOM-1070 can we build for release or does this have signing issues?
    Dir.chdir("application/android") do
      ant = 'ant'
      if $HOST.name == 'windows'
          ant = 'ant.bat'
      end
      sh "#{ant} clean #{CFG[:TARGET_ANDROID_BUILD_TYPE]}"
    end

    # Copy APKs to artifacts.
    FileUtils.mkdir_p "artifacts/android-arm"
    FileUtils.cp_r("application/android/bin/#{AndroidToolchain::apkName}", "#{$OUTPUT_DIRECTORY}/android-arm/LoomDemo.apk")
    FileUtils.cp_r("tools/apktool/apktool.jar", "#{$OUTPUT_DIRECTORY}/android-arm")
  end

  desc "Builds Ubuntu Linux"
  task :ubuntu => [] do
    puts "== Skipped Ubuntu =="

    if false
	
    puts "== Building Ubuntu =="
    FileUtils.mkdir_p("#{$ROOT}/build/loom-linux-x86")
    Dir.chdir("#{$ROOT}/build/loom-linux-x86") do
      sh "cmake -DLOOM_BUILD_JIT=#{CFG[:USE_LUA_JIT]} -DLUA_GC_PROFILE_ENABLED=#{CFG[:ENABLE_LUA_GC_PROFILE]} -G \"Unix Makefiles\" -DCMAKE_BUILD_TYPE=#{CFG[:BUILD_TARGET]} #{$buildDebugDefine} #{$buildAdMobDefine} #{$buildFacebookDefine} #{$ROOT}"
      sh "make -j#{$HOST.num_cores}"
    end

    Rake::Task["utility:compileScripts"].invoke
    Rake::Task["utility:compileTools"].invoke
	end
	
  end

  desc "Populate git version information"
  task :get_git_details do
    git_rev_long = `git rev-parse HEAD`
    git_rev_short = `git rev-parse --short HEAD`

    puts "Long: #{git_rev_long}"
    puts "Short: #{git_rev_short}"
  end
  
end

# FIXME: At some point test should just run the tests and not try to build OSX
# mainly we need to make windows work
desc "Runs all unit tests and exports results to artifacts/testResults.xml"
task :test => ['build:desktop'] do
  Dir.chdir("tests") do
    sh "#{$ROOT}/tests/unittest-#{$HOST.arch}"
  end
  Dir.chdir("sdk") do
    sh "#{$LSC_BINARY} --unittest --xmlfile #{$ROOT}/artifacts/testResults.xml"
  end
end

namespace :deploy do

  desc "Deploy sdk locally"
  task :sdk, [:sdk_version] => ['build:all', 'generate:docs'] do |t, args|


    Rake::Task["package:sdk"].invoke

    args.with_defaults(:sdk_version => CFG[:TARGET_SDK_VER])
    sdk_path = File.join("#{ENV['HOME']}/.loom", "sdks", args[:sdk_version])

    # Remove the previous version
    FileUtils.rm_rf sdk_path if File.directory? sdk_path
    unzip_file("pkg/loomsdk.zip", sdk_path)

    puts "Installing sdk locally for loomcli under the name #{args[:sdk_version]}"
  end

  desc "Deploy the free version of the sdk locally"
  task :free_sdk, [:sdk_version] => ['build:all', 'generate:docs'] do |t, args|

    Rake::Task["package:free_sdk"].invoke

    args.with_defaults(:sdk_version => CFG[:TARGET_SDK_VER])
    sdk_path = File.join("#{ENV['HOME']}/.loom", "sdks", args[:sdk_version])

    # Remove the previous version
    FileUtils.rm_rf sdk_path if File.directory? sdk_path
    unzip_file("pkg/freesdk.zip", sdk_path)

    puts "Installing sdk locally for loomcli under the name #{args[:sdk_version]}"
  end

  desc "Deploy debug build to android."
  task :android do
    Dir.chdir("application/android") do
      if CFG[:TARGET_ANDROID_BUILD_TYPE] == "debug"
        sh "ant installd"
      elsif CFG[:TARGET_ANDROID_BUILD_TYPE] == "release"
        sh "ant installr"
      else
        abort("Unknown android build type #{CFG[:TARGET_ANDROID_BUILD_TYPE]}, update deploy:android task to know about new type.")
      end
    end
  end

end

namespace :update do
  desc "Updates the scripts in an already deployed sdk."
  task :sdk, [:sdk_version] do |t, args|
    args.with_defaults(:sdk_version => CFG[:TARGET_SDK_VER])
    sdk = args[:sdk_version]
    sdk_path = File.join("#{ENV['HOME']}/.loom", "sdks", sdk)

    if !File.exists?(sdk_path)
      abort("SDK #{sdk} does not exist! Please run `rake deploy:sdk[#{sdk}]` to build it.")
    end

    Rake::Task["utility:compileScripts"].invoke

    FileUtils.cp_r("sdk/libs", sdk_path);

    puts "Updated sdk locally for loomcli under the name #{sdk}"
  end
end
