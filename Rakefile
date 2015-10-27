require 'rubygems'
require 'rbconfig'

puts "== Executing as '#{ENV['USER']}' =="

###############################
# BUILD CONFIGURATION VARIABLES
###############################

# Specify the build target - Debug, Release, RelMinSize, RelWithDebug
$buildTarget="Debug" # "Debug"

# the sdk_version name that will be generated when this sdk is deployed (default = "dev")
$targetSDKVersion = "dev"

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

###############################
# GLOBALS
###############################

ROOT = Dir.pwd

def flag_enabled?(flag)
  flag.to_i == 1 || flag == 'true'
end

# If 1, then we link against LuaJIT. If 0, we use classic Lua VM.
$doBuildJIT=1

# If 1, then LUA GC profiling code is enabled
$doEnableLuaGcProfile= 1

# Whether or not to include Admob and/or Facebook in the build... for Great Apple Compliance!
$doBuildAdmob=0
$doBuildFacebook=0

# Relative path of the telemetry client files in the SDK 
$telemetryClient = "telemetry/www/"
# Include these files (Ruby Dir.glob syntax)
# If you change this, you should probably update the
# .gitignore file in tools/telemetry/www/ so people
# downloading the SDK can build straight away
$telemetryClientInclude = [
  "*.*",
  "css/**/*.*",
  "js/**/*.*",
  # Semantic UI
  "semantic/dist/**/*.*",
]
# Exclude these files
# Note that simple paths from .gitignore are already
# automatically excluded (e.g. unnecessary semantic ui files)
$telemetryClientExclude = [
  "semantic.json",
  "LICENSE.txt",
]

# Allow disabling Loom doc generation, as it can be very slow.
# Disabled by default, set environment variable 'LOOM_BUILD_DOCS'
$buildDocs = ENV['LOOM_BUILD_DOCS'] == "1" || ENV['LOOM_BUILD_DOCS'] == "true"

def version_outdated?(current, required)
  (Gem::Version.new(current.dup) < Gem::Version.new(required.dup))
end

# Ruby version check.
$RUBY_REQUIRED_VERSION = '1.8.7'
ruby_err = "LoomSDK requires ruby version #{$RUBY_REQUIRED_VERSION} or newer.\nPlease go to https://www.ruby-lang.org/en/downloads/ and install the latest version."
abort(ruby_err) if version_outdated?(RUBY_VERSION, $RUBY_REQUIRED_VERSION)

# Loom SDK version
$LOOM_VERSION = File.new("VERSION").read.chomp

# Host operating system check
include RbConfig

case CONFIG['host_os']
   when /mswin|windows|mingw32/i
      $LOOM_HOST_OS = "windows"
   when /darwin/i
      $LOOM_HOST_OS = "osx"
   when /linux-gnu/i
      $LOOM_HOST_OS = "linux"
   else
      abort("Unknown host config: Config::CONFIG['host_os']: #{Config::CONFIG['host_os']}")
end

# CMake version check
def cmake_version
  %x[cmake --version].lines.first.gsub("cmake version ", "")
end

def installed?(tool)
  cmd = "which #{tool}" unless ($LOOM_HOST_OS == 'windows')
  cmd = "where #{tool} > nul 2>&1" if ($LOOM_HOST_OS == 'windows')
  %x(#{cmd})
  return ($? == 0)
end

def writeStub(platform)
  FileUtils.mkdir_p("artifacts")
  File.open("artifacts/README.#{platform.downcase}", "w") {|f| f.write("#{platform} is not supported right now.")}
end

$CMAKE_REQUIRED_VERSION = ($LOOM_HOST_OS == "linux") ? '2.8.7' : '2.8.9'
cmake_err = "LoomSDK requires CMake version #{$CMAKE_REQUIRED_VERSION} or above.\nPlease go to http://www.cmake.org/ and install the latest version."
abort(cmake_err) if (!installed?('cmake') || version_outdated?(cmake_version, $CMAKE_REQUIRED_VERSION))

# For matz's sake just include rubyzip directly.
path = File.expand_path(File.join(File.dirname(__FILE__), 'build', 'libs'))
$LOAD_PATH << path
require 'zip'
require 'zip/file'

# $buildDebugDefine will trigger the LOOM_DEBUG define if this is a Debug build target
if $buildTarget == "Debug"
  $buildDebugDefine="-DLOOM_IS_DEBUG=1"
else
  $buildDebugDefine="-DLOOM_IS_DEBUG=0"
end

# set some build defines up here to keep it cleaner below
$buildAdMobDefine = "-DLOOM_BUILD_ADMOB=#{$doBuildAdmob}"
$buildFacebookDefine = "-DLOOM_BUILD_FACEBOOK=#{$doBuildFacebook}"

# How many cores should we use to build?
if $LOOM_HOST_OS == 'osx'
  $numCores = Integer(`sysctl hw.ncpu | awk '{print $2}'`)
elsif $LOOM_HOST_OS == 'windows'
  $numCores = ENV['NUMBER_OF_PROCESSORS']
else
  $numCores = Integer(`cat /proc/cpuinfo | grep processor | wc -l`)
end

# OSX specific settings

if $LOOM_HOST_OS == 'osx'
  arch = `uname -m`.chomp
  if arch == 'x86_64' then
    HOST_ISX64 = '1'
  elsif arch == 'i386' then
    HOST_ISX64 = '0'
  else
    abort("Unsupported OSX platform #{arch}!")
  end
end

# Windows specific checks and settings
if $LOOM_HOST_OS == 'windows'
  # This gets the true architecture of the machine, not the target architecture of the currently executing binary (that is what %PROCESSOR_ARCHITECTURE% returns)
  # => Valid values seem to only be "AMD64", "IA64", or "x86"
  proc_arch = `reg query "HKLM\\System\\CurrentControlSet\\Control\\Session Manager\\Environment" /v PROCESSOR_ARCHITECTURE`
  if proc_arch =~ /\.*64/
    WINDOWS_PROCARCH_BITS = '64'
    HOST_ISX64 = '1'
    WINDOWS_ANDROID_PREBUILT_DIR = 'windows-x86_64'
  else
    WINDOWS_PROCARCH_BITS = '32'
    HOST_ISX64 = '0'
    WINDOWS_ANDROID_PREBUILT_DIR = 'windows'
    proc_arch = ''
  end

  require 'win32/registry'

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

if $HOST_ISX64 == '1' then
  HOST_ARTIFACTS = "#{ROOT}/artifacts/#{$LOOM_HOST_OS}-x64"
else
  HOST_ARTIFACTS = "#{ROOT}/artifacts/#{$LOOM_HOST_OS}-x86"
end

require 'rake/clean'
require 'rake/packagetask'
require 'pathname'
require 'shellwords'

if $LOOM_HOST_OS == 'windows'
    $LSC_BINARY = "#{HOST_ARTIFACTS}\\tools\\lsc.exe"
else
    $LSC_BINARY = "#{HOST_ARTIFACTS}/tools/lsc"
end

# Report build configuration values
puts ''
puts "LoomSDK (#{$LOOM_VERSION}) Rakefile running on Ruby v#{RUBY_VERSION}"
puts "  CMake version: #{cmake_version}"
puts "  Build type: #{$buildTarget}"
puts "  Using JIT? #{flag_enabled?($doBuildJIT)} | Building AdMob? #{flag_enabled?($doBuildAdmob)} | Building FacebookSDK? #{flag_enabled?($doBuildFacebook)}"
puts "  Detected Windows #{WINDOWS_PROCARCH_BITS} Bit PROCESSOR_ARCHITECTURE: '#{proc_arch}'" if $LOOM_HOST_OS == 'windows'
puts "  Detected Non-Windows Platform" unless $LOOM_HOST_OS == 'windows'
puts "  Building with #{$numCores} cores."
puts "  AndroidSDK: #{$targetAndroidSDK} | AndroidBuildType: #{$targetAndroidBuildType} | Target APK: #{$targetAPKName}"
puts "  iOS SDK version: #{$targetIOSSDK}"
puts "  Building Loom docs? #{$buildDocs}"
puts ''

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
    their_sure = STDIN.gets
    if their_sure.chomp! == "yes" || their_sure.chomp! == "y"
      sh "git clean -fdx"
    else
      puts "Phew, that was close!"
    end
  end
end

namespace :generate do

  desc "Generates API docs for the loomscript sdk"
  task :docs => ['build:desktop'] do

    if $buildDocs || ARGV.include?('generate:docs')
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
  task :regen => $LSC_BINARY do
    puts "===== Recompiling loomlibs ====="
    Dir.chdir("sdk") do
      sh "#{$LSC_BINARY} Main.build"
    end
    FileUtils.cp_r("sdk/libs", "artifacts/")

    puts "===== Recreating the docs ====="
    Dir.chdir("docs") do
      ENV['LOOM_VERSION'] = $LOOM_VERSION unless ENV['LOOM_VERSION']
      load "./main.rb"
    end
    FileUtils.mkdir_p "artifacts/docs"
    FileUtils.cp_r "docs/output/.", "artifacts/docs/"
  end

  desc "Opens the current docs in a web browser"
  task :open => $DOCS_INDEX do
    case $LOOM_HOST_OS
    when 'windows'
      `start artifacts/docs/index.html`
    when 'osx'
      `open artifacts/docs/index.html`
    else
      abort "not sure how to open '#{$DOCS_INDEX}' on #{$LOOM_HOST_OS}"
    end
  end

  desc "Rebuilds docs and opens in browser"
  task :refresh => ['docs:regen', 'docs:open']

end

namespace :utility do

  desc "Builds lsc if it doesn't exist"
  file $LSC_BINARY do
    Rake::Task['build:desktop'].invoke
    puts " *** lsc built!"
  end

  desc "Compile scripts and report any errors."
  task :compileScripts => $LSC_BINARY do
    puts "===== Compiling Core Scripts ====="
    Dir.chdir("sdk") do
      sh "ls #{HOST_ARTIFACTS}/"
      sh "#{$LSC_BINARY} Main.build"
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
        sh "#{$LSC_BINARY}"
      end
      
      # Clean up the libs and bin folders to save tons of space.
      FileUtils.rm_r("docs/examples/#{args[:name]}/libs")
      FileUtils.rm_r("docs/examples/#{args[:name]}/bin")
  end

  desc "Run demo"
  task :runDemo, [:name] => $LSC_BINARY do |t, args|
      puts "===== Running #{args[:name]} ====="
      expandedArtifactsPath = File.expand_path($OUTPUT_DIRECTORY)
      if $LOOM_HOST_OS == 'osx'
        Rake::Task["build:osx"].invoke
        Rake::Task["utility:compileScripts"].invoke
        FileUtils.cp_r("./sdk/libs", "./docs/examples/#{args[:name]}")
        FileUtils.mkdir_p("./docs/examples/#{args[:name]}/bin")
        Dir.chdir("docs/examples/#{args[:name]}") do
          sh "#{$LSC_BINARY}"
          sh "#{HOST_ARTIFACTS}/LoomDemo.app/Contents/MacOS/LoomDemo"
        end
      else
        Rake::Task["build:windows"].invoke
        Rake::Task["utility:compileScripts"].invoke
        FileUtils.cp_r("./sdk/libs", "./docs/examples/#{args[:name]}")
        FileUtils.mkdir_p("./docs/examples/#{args[:name]}/bin")
        Dir.chdir("docs/examples/#{args[:name]}") do
          sh "#{$LSC_BINARY}"
          sh "#{HOST_ARTIFACTS}/LoomDemo.exe"
        end
      end
  end

  desc "Run the LoomDemo in artifacts"
  task :run => "build:desktop" do

    puts "===== Launching Application ====="

  if $LOOM_HOST_OS == 'osx'

    appPath = Dir.glob("#{HOST_ARTIFACTS}/*.app")[0]
    appPrefix = get_app_prefix(appPath)

    # Run it.
    Dir.chdir(appPath) do
      sh "./Contents/MacOS/#{appPrefix}"
    end
  else

    #Run it under Windows
    Dir.chdir("#{HOST_ARTIFACTS}") do
      sh "LoomDemo.exe"
    end
  end

  end

  desc "Run app under GDB on OSX"
  task :debug => ['build:osx'] do
    puts "===== Launching Application ====="

    appPath = Dir.glob("#{HOST_ARTIFACTS}/*.app")[0]
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
    if $LOOM_HOST_OS == 'osx'
		Rake::Task["build:ios"].invoke
    end
  end

  desc "Builds the native desktop platform (OSX or Windows)"
  task :desktop do
    if $LOOM_HOST_OS == 'windows'
      Rake::Task["build:windows"].invoke
    elsif $LOOM_HOST_OS == 'osx'
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
    FileUtils.mkdir_p("#{$OUTPUT_DIRECTORY}/ios-arm")
    FileUtils.cp("tools/fruitstrap/fruitstrap", "#{$OUTPUT_DIRECTORY}/ios-arm/")
  end

  desc "Builds OS X"
  task :osx => [] do

    # OS X build is currently not supported under Windows
    if $LOOM_HOST_OS != 'windows'

      puts "== Building OS X =="

      if $doBuildJIT == 1 then
        FileUtils.mkdir_p("build/luajit-osx-x86")
        Dir.chdir("build/luajit-osx-x86") do
          sh "cmake -G Xcode -DCMAKE_BUILD_TYPE=#{$buildTarget} -DLUAJIT_X64=0 -DLUAJIT_OS=LUAJIT_OS_OSX -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile} #{ROOT}/loom/vendor/luajit"
          sh "xcodebuild -configuration #{$buildTarget}"
        end
      end

      FileUtils.mkdir_p("#{ROOT}/build/loom-osx-x86")
      Dir.chdir("#{ROOT}/build/loom-osx-x86") do
        sh "cmake -DLOOM_BUILD_JIT=#{$doBuildJIT} -DLOOM_BUILD_64BIT=0 -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile} -G Xcode -DCMAKE_BUILD_TYPE=#{$buildTarget} -DLUAJIT_BUILD_DIR=#{ROOT}/build/luajit-osx-x86 #{$buildDebugDefine} #{$buildAdMobDefine} #{$buildFacebookDefine} #{ROOT}"
        sh "xcodebuild -configuration #{$buildTarget}"
      end

      if HOST_ISX64 == '1' then
        if $doBuildJIT == 1 then
          FileUtils.mkdir_p("build/luajit-osx-x64")
          Dir.chdir("build/luajit-osx-x64") do
            sh "cmake -G Xcode -DCMAKE_BUILD_TYPE=#{$buildTarget} -DLUAJIT_OS=LUAJIT_OS_OSX -DLUAJIT_X64=1 -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile} #{ROOT}/loom/vendor/luajit"
            sh "xcodebuild -configuration #{$buildTarget}"
          end
        end

        FileUtils.mkdir_p("#{ROOT}/build/loom-osx-x64")
        Dir.chdir("#{ROOT}/build/loom-osx-x64") do
          sh "cmake -DLOOM_BUILD_JIT=#{$doBuildJIT} -DLOOM_BUILD_64BIT=1 -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile} -G Xcode -DCMAKE_BUILD_TYPE=#{$buildTarget} -DLUAJIT_BUILD_DIR=#{ROOT}/build/luajit-osx-x64 #{$buildDebugDefine} #{$buildAdMobDefine} #{$buildFacebookDefine} #{ROOT}"
          sh "xcodebuild -configuration #{$buildTarget}"
        end
      end

      # copy libs
      FileUtils.cp_r("sdk/libs", "#{$OUTPUT_DIRECTORY}")

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

      #copy assets
      FileUtils.mkdir_p("#{$OUTPUT_DIRECTORY}/assets")

    end

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
        puts "**********************************************"
        puts "WARNING: Using default iOS signing identity. Set IOS_SIGNING_IDENTITY to control the identity used."
        puts "**********************************************"
        args.with_defaults(:sign_as => "iPhone Developer")
      end
      puts "*** Signing Identity = #{args.sign_as}"

      rootFolder = Dir.pwd
      luajit_ios_dir = File.join(rootFolder, "build", "luajit-ios") 

      ISDK = "/Applications/XCode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer"
      ISDKVER = "iPhoneOS#{$targetIOSSDK}.sdk"
      ISDKP = ISDK + "/usr/bin/"
      ISDKF = "-arch armv7 -isysroot #{ISDK}/SDKs/#{ISDKVER}"

      ENV["ISDK"] = ISDK
      ENV["ISDKVER"] = ISDKVER
      ENV["ISDKP"] = ISDKP
      ENV["ISDKF"] = ISDKF

      FileUtils.mkdir_p("#{ROOT}/build/loom-ios-arm")

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

      sdkroot="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS#{$targetIOSSDK}.sdk"

      if $doBuildJIT == 1 then
        FileUtils.mkdir_p("build/luajit-ios-arm-bootstrap")
        Dir.chdir("build/luajit-ios-arm-bootstrap") do
          sh "cmake -G Xcode -DCMAKE_OSX_ARCHITECTURES=i386 -DBOOTSTRAP_ONLY=1 -DLUA_TARGET_ARCH=arm -DLUAJIT_OS=LUAJIT_OS_OSX -DCMAKE_BUILD_TYPE=#{$buildTarget} #{ROOT}/loom/vendor/luajit"
          sh "cmake --build ."
        end

        FileUtils.mkdir_p("build/luajit-ios-arm")
        Dir.chdir("build/luajit-ios-arm") do
          sh "cmake -G Xcode -DTARGET_ONLY=1 -DBOOTSTRAP_PATH=#{ROOT}/build/luajit-ios-arm-bootstrap -DLUA_TARGET_ARCH=arm -DLUAJIT_OS=LUAJIT_OS_OSX -DCMAKE_BUILD_TYPE=#{$buildTarget} -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile} #{ROOT}/loom/vendor/luajit"
          sh "xcodebuild -configuration #{$buildTarget} CODE_SIGN_IDENTITY=\"#{args.sign_as}\" CODE_SIGN_RESOURCE_RULES_PATH=#{sdkroot}/ResourceRules.plist"
        end
      end

      # TODO: Find a way to resolve resources in xcode for ios.
      Dir.chdir("#{ROOT}/build/loom-ios-arm") do
        sh "cmake -DLOOM_BUILD_IOS=1 -DLUAJIT_BUILD_DIR=#{ROOT}/build/luajit-ios-arm -DLOOM_BUILD_JIT=#{$doBuildJIT} -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile} -DLOOM_IOS_VERSION=#{$targetIOSSDK} #{$buildDebugDefine} #{$buildAdMobDefine} #{$buildFacebookDefine} -G Xcode #{ROOT}"
        sh "xcodebuild -configuration #{$buildTarget} CODE_SIGN_IDENTITY=\"#{args.sign_as}\" CODE_SIGN_RESOURCE_RULES_PATH=#{sdkroot}/ResourceRules.plist"
      end

      # TODO When we clean this up... we should have get_app_prefix return and object with, appPath,
      # appNameMatch, appName and appPrefix

      # Find the .app in the build folder.
      appPath = Dir.glob("#{ROOT}/build/loom-ios-arm/application/#{$buildTarget}-iphoneos/*.app")[0]
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
      if $buildTarget == "Debug"
        dsymPath = Dir.glob("#{ROOT}/build/loom-ios-arm/application/#{$buildTarget}-iphoneos/*.dSYM")[0]
        puts "dSYM path found: #{dsymPath}"
        FileUtils.cp_r(dsymPath, full_output_path)
      end
    end
  end

  desc "Builds Windows"
  task :windows => [] do
    puts "== Building Windows =="

    if $doBuildJIT == 1 then
        FileUtils.mkdir_p("build/luajit-windows-x86")
        Dir.chdir("build/luajit-windows-x86") do
            sh "cmake #{ROOT}/loom/vendor/luajit/ -G \"#{get_vs_name()}\" -DLUAJIT_X64=0 -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile}"
            sh "msbuild /verbosity:m ALL_BUILD.vcxproj /p:Configuration=#{$buildTarget}"
        end
    end

    FileUtils.mkdir_p("#{ROOT}/build/loom-windows-x86")
    Dir.chdir("#{ROOT}/build/loom-windows-x86") do
      sh "cmake -G \"#{get_vs_name()}\" -DLOOM_BUILD_JIT=#{$doBuildJIT} -DLOOM_BUILD_64BIT=0 -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile} -DLOOM_BUILD_NUMCORES=#{$numCores} #{$buildDebugDefine} #{$buildAdMobDefine} #{$buildFacebookDefine} -DLUAJIT_BUILD_DIR=\"#{ROOT}/build/luajit-windows-x86\" #{ROOT}"
      sh "msbuild /verbosity:m LoomEngine.sln /p:Configuration=#{$buildTarget}"
    end

    if HOST_ISX64 == '1' then

        if $doBuildJIT == 1 then
            FileUtils.mkdir_p("build/luajit-windows-x64")
            Dir.chdir("build/luajit-windows-x64") do
                sh "cmake #{ROOT}/loom/vendor/luajit/ -G \"#{get_vs_name()} Win64\" -DLUAJIT_X64=1  -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile}"
                sh "msbuild /verbosity:m ALL_BUILD.vcxproj /p:Configuration=#{$buildTarget}"
            end
        end

        FileUtils.mkdir_p("#{ROOT}/build/loom-windows-x64")
        Dir.chdir("#{ROOT}/build/loom-windows-x64") do
          sh "cmake -G \"#{get_vs_name()} Win64\" -DLOOM_BUILD_64BIT=1 -DLOOM_BUILD_JIT=#{$doBuildJIT} -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile} -DLOOM_BUILD_NUMCORES=#{$numCores} #{$buildDebugDefine} #{$buildAdMobDefine} #{$buildFacebookDefine} -DLUAJIT_BUILD_DIR=\"#{ROOT}/build/luajit-windows-x64\" #{ROOT}"
          sh "msbuild /verbosity:m LoomEngine.sln /p:Configuration=#{$buildTarget}"
        end
    end

    Rake::Task["utility:compileScripts"].invoke

    # build ldb
    Dir.chdir("sdk") do
      sh "#{$LSC_BINARY} LDB.build"
    end
    
    # build testexec
    Dir.chdir("sdk") do
      sh "#{$LSC_BINARY} TestExec.build"
    end

    puts "Copying to #{HOST_ARTIFACTS}"

    # copy libs
    FileUtils.cp_r("sdk/libs", "#{$OUTPUT_DIRECTORY}")
    FileUtils.cp_r("sdk/bin/LDB.loom", "#{$OUTPUT_DIRECTORY}/libs")
    FileUtils.cp_r("sdk/bin/TestExec.loom", "#{$OUTPUT_DIRECTORY}/libs")
    FileUtils.cp_r("sdk/src/testexec/loom.config", "#{$OUTPUT_DIRECTORY}/libs/TestExec.config")
    FileUtils.cp_r('sdk/bin', "#{HOST_ARTIFACTS}")
    FileUtils.cp_r('sdk/assets', "#{$OUTPUT_DIRECTORY}")
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
	
    if $LOOM_HOST_OS == "windows"

      # WINDOWS
      FileUtils.mkdir_p("#{ROOT}/build/loom-android-arm")
      Dir.chdir("#{ROOT}/build/loom-android-arm") do
        sh "cmake -DCMAKE_TOOLCHAIN_FILE=#{ROOT}/build/cmake/loom.android.toolchain.cmake -DLUAJIT_BUILD_DIR=#{ROOT}/loom/vendor/luajit_windows_android/luajit_android/lib #{$buildDebugDefine} #{$buildAdMobDefine} #{$buildFacebookDefine} -DANDROID_NDK_HOST_X64=#{HOST_ISX64} -DANDROID_ABI=armeabi-v7a  -DLOOM_BUILD_JIT=#{$doBuildJIT} -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile} -DANDROID_NATIVE_API_LEVEL=14 -DCMAKE_BUILD_TYPE=#{$buildTarget} -G\"MinGW Makefiles\" -DCMAKE_MAKE_PROGRAM=\"%ANDROID_NDK%\\prebuilt\\#{WINDOWS_ANDROID_PREBUILT_DIR}\\bin\\make.exe\" #{ROOT}"
        sh "cmake --build ."
      end

      puts "*** Building against AndroidSDK " + $targetAndroidSDK
      api_id = get_android_api_id($targetAndroidSDK)

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

      sh "xcopy /Y /I sdk\\bin\\*.loom application\\android\\assets\\bin"
      sh "xcopy /Y /I sdk\\assets\\*.* application\\android\\assets\\assets"

      # TODO: LOOM-1070 can we build for release or does this have signing issues?
      Dir.chdir("application/android") do
        sh "ant.bat clean #{$targetAndroidBuildType}"
      end

      # Copy APKs to artifacts.
      FileUtils.mkdir_p "artifacts/android-arm"
      sh "echo f | xcopy /F /Y application\\android\\bin\\#{$targetAPKName} #{$OUTPUT_DIRECTORY}\\android-arm\\LoomDemo.apk"

      FileUtils.cp_r("tools/apktool/apktool.jar", "#{$OUTPUT_DIRECTORY}/android-arm")
    else
      # OSX / LINUX

      if $doBuildJIT == 1 then
        FileUtils.mkdir_p("build/luajit-android-arm-bootstrap")
        Dir.chdir("build/luajit-android-arm-bootstrap") do
          sh "cmake -G Xcode -DCMAKE_OSX_ARCHITECTURES=i386 -DBOOTSTRAP_ONLY=1 -DLUA_TARGET_ARCH=arm -DLUAJIT_OS=LUAJIT_OS_LINUX -DCMAKE_BUILD_TYPE=#{$buildTarget} #{ROOT}/loom/vendor/luajit"
          sh "cmake --build ."
        end

        FileUtils.mkdir_p("build/luajit-android-arm")
        Dir.chdir("build/luajit-android-arm") do
          sh "cmake -DCMAKE_TOOLCHAIN_FILE=#{ROOT}/build/cmake/loom.android.toolchain.cmake -DTARGET_ONLY=1 -DBOOTSTRAP_PATH=#{ROOT}/build/luajit-android-arm-bootstrap -DLUA_TARGET_ARCH=arm -DLUAJIT_OS=LUAJIT_OS_LINUX -DCMAKE_BUILD_TYPE=#{$buildTarget} -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile} #{ROOT}/loom/vendor/luajit"
          sh "cmake --build ."
        end
      end

      FileUtils.mkdir_p("#{ROOT}/build/loom-android-arm")
      Dir.chdir("#{ROOT}/build/loom-android-arm") do
        sh "cmake -DCMAKE_TOOLCHAIN_FILE=#{ROOT}/build/cmake/loom.android.toolchain.cmake -DLUAJIT_BUILD_DIR=#{ROOT}/build/luajit-android-arm #{$buildDebugDefine} #{$buildAdMobDefine} #{$buildFacebookDefine} -DANDROID_ABI=armeabi-v7a  -DLOOM_BUILD_JIT=#{$doBuildJIT} -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile} -DANDROID_NATIVE_API_LEVEL=14 -DCMAKE_BUILD_TYPE=#{$buildTarget} #{ROOT}"
        sh "make -j#{$numCores}"
      end

      api_id = get_android_api_id($targetAndroidSDK)

      Dir.chdir("loom/vendor/facebook/android") do
        puts "*** Building against AndroidSDK " + $targetAndroidSDK
        sh "android update project --name FacebookSDK --subprojects --target #{api_id} --path ."
      end

      Dir.chdir("loom/engine/sdl2/platform/android/java") do
        puts "*** Building against AndroidSDK " + $targetAndroidSDK
        sh "android update project --name SDL2Lib --subprojects --target #{api_id} --path ."
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
      FileUtils.mkdir_p "#{$OUTPUT_DIRECTORY}/android-arm/"

      sh "cp application/android/bin/#{$targetAPKName} #{$OUTPUT_DIRECTORY}/android-arm/LoomDemo.apk"

      FileUtils.cp_r("tools/apktool/apktool.jar", "#{$OUTPUT_DIRECTORY}/android-arm")
    end
  end

  desc "Builds Ubuntu Linux"
  task :ubuntu => [] do
    puts "== Skipped Ubuntu =="

    if false
	
    puts "== Building Ubuntu =="
    FileUtils.mkdir_p("#{ROOT}/build/loom-linux-x86")
    Dir.chdir("#{ROOT}/build/loom-linux-x86") do
      sh "cmake -DLOOM_BUILD_JIT=#{$doBuildJIT} -DLUA_GC_PROFILE_ENABLED=#{$doEnableLuaGcProfile} -G \"Unix Makefiles\" -DCMAKE_BUILD_TYPE=#{$buildTarget} #{$buildDebugDefine} #{$buildAdMobDefine} #{$buildFacebookDefine} #{ROOT}"
      sh "make -j#{$numCores}"
    end

    Rake::Task["utility:compileScripts"].invoke

    # build ldb
    Dir.chdir("sdk") do
      sh "#{$LSC_BINARY} LDB.build"
    end
    
    # build testexec
    Dir.chdir("sdk") do
      sh "#{$LSC_BINARY} TestExec.build"
    end
    
    puts "Copying to #{$OUTPUT_DIRECTORY}/ubuntu"

    # copy libs
    FileUtils.cp_r("sdk/libs", "#{$OUTPUT_DIRECTORY}")
    FileUtils.cp_r("sdk/bin/LDB.loom", "#{$OUTPUT_DIRECTORY}/libs")
    FileUtils.cp_r("sdk/bin/TestExec.loom", "#{$OUTPUT_DIRECTORY}/libs")
    FileUtils.cp_r("sdk/src/testexec/loom.config", "#{$OUTPUT_DIRECTORY}/libs/TestExec.config")
    FileUtils.cp_r('sdk/bin', "#{HOST_ARTIFACTS}")
    FileUtils.cp_r('sdk/assets', "#{$OUTPUT_DIRECTORY}")

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
    if HOST_ISX64 == '1' then
      sh "#{ROOT}/tests/unittest-x64"
    else
      sh "#{ROOT}/tests/unittest-x86"
    end
  end
  Dir.chdir("sdk") do
    sh "#{$LSC_BINARY} --unittest --xmlfile #{ROOT}/artifacts/testResults.xml"
  end
end

namespace :deploy do

  desc "Deploy sdk locally"
  task :sdk, [:sdk_version] => ['package:sdk'] do |t, args|
    args.with_defaults(:sdk_version => $targetSDKVersion)
    sdk_path = File.join("#{ENV['HOME']}/.loom", "sdks", args[:sdk_version])

    # Remove the previous version
    FileUtils.rm_rf sdk_path if File.directory? sdk_path
    unzip_file("pkg/loomsdk.zip", sdk_path)

    puts "Installing sdk locally for loomcli under the name #{args[:sdk_version]}"
  end

  desc "Deploy the free version of the sdk locally"
  task :free_sdk, [:sdk_version] => ['package:free_sdk'] do |t, args|
    args.with_defaults(:sdk_version => $targetSDKVersion)
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
    args.with_defaults(:sdk_version => $targetSDKVersion)
    sdk = args[:sdk_version]
    sdk_path = File.join("#{ENV['HOME']}/.loom", "sdks", sdk)

    if !File.exists?(sdk_path)
      abort("SDK #{sdk} does not exist! Please run `rake deploy:sdk[#{sdk}]` to build it.")
    end

    puts "===== Compiling Core Scripts ====="
    Dir.chdir("sdk") do
      sh "#{$LSC_BINARY} Main.build"
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

    omit_files = %w[ examples.zip loomsdk.zip certs/LoomDemoBuild.mobileprovision loom/vendor/telemetry-01052012 pkg/ artifacts/ docs/output build/ ]

    Zip::File.open("nativesdk.zip", 'w') do |zipfile|
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
    
    # Package examples skipping bloat.
    Zip::File.open("pkg/examples.zip", 'w') do |zipfile|
      Dir["docs/examples/**/**"].each do |file|
      	next if File.extname(file) == ".loomlib"
      	next if File.extname(file) == ".loom"
        zipfile.add(file.sub("docs/examples/", ''),file)
      end
    end

    puts "== Examples Packaged =="
  end

  desc "Packages SDK"
  task :sdk => ['build:all', "generate:docs"] do
    puts "== Packaging Loom SDK =="

    prepare_free_sdk

    FileUtils.rm_rf "pkg/sdk/bin/android-arm"

    # iOS is currently not supported under Windows
    if $LOOM_HOST_OS != "windows"
      # ============================================================= iOS
      # put together a folder to zip up
      FileUtils.mkdir_p "pkg/sdk/bin/ios-arm/tools"
      FileUtils.mkdir_p "pkg/sdk/bin/ios-arm/bin"

      FileUtils.cp_r("artifacts/ios-arm/fruitstrap", "pkg/sdk/bin/ios-arm/tools")
      # add the ios app bundle
      FileUtils.cp_r("artifacts/ios-arm/LoomDemo.app", "pkg/sdk/bin/ios-arm/bin")
      if $buildTarget == "Debug"
        FileUtils.cp_r("artifacts/ios-arm/LoomDemo.app.dSYM", "pkg/sdk/bin/ios-arm/bin")
      end

      # Strip out the bundled assets and binaries
      FileUtils.rm_rf "pkg/sdk/bin/ios-arm/bin/LoomDemo.app/assets"
      FileUtils.rm_rf "pkg/sdk/bin/ios-arm/bin/LoomDemo.app/bin"
      FileUtils.rm_rf "pkg/sdk/bin/ios-arm/bin/LoomDemo.app/libs"

    end

    FileUtils.mkdir_p "pkg/sdk/bin/android-arm/tools"
    FileUtils.cp_r("artifacts/android-arm/apktool.jar", "pkg/sdk/bin/android-arm/tools")

    # ============================================================= Android
    # decompile the android apk
    FileUtils.mkdir_p "pkg/sdk/bin/android-arm/bin"
    decompile_apk("application/android/bin/#{$targetAPKName}","pkg/sdk/bin/android-arm/bin")

    # Strip out the bundled assets and binaries
    FileUtils.rm_rf "pkg/sdk/bin/android-arm/bin/assets/assets"
    FileUtils.rm_rf "pkg/sdk/bin/android-arm/bin/assets/bin"
    FileUtils.rm_rf "pkg/sdk/bin/android-arm/bin/assets/libs"
    FileUtils.rm_rf "pkg/sdk/bin/android-arm/bin/META-INF"

    if $LOOM_HOST_OS == 'windows'
      # Under windows copy the .so file over
      sh "if not exist pkg\\sdk\\bin\\android-arm\\bin\\lib mkdir pkg\\sdk\\bin\\android-arm\\bin\\lib"
      sh "for /d %F in (libs\\*.*) do xcopy /Y /I /E /F %F\\*.so pkg\\sdk\\bin\\android-arm\\bin\\lib\\%~nF"
    end

    require_dependencies

    puts "Compressing Loom SDK..."
    Zip::File.open("pkg/loomsdk.zip", 'w') do |zipfile|
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

    Zip::File.open("pkg/loomsdk.zip", 'w') do |zipfile|
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
  sh "java -jar tools/apktool/apktool.jar d -f #{file} -o #{destination}"
end

def require_dependencies
  begin
    require 'rubygems'
    require 'zip'
    require 'zip/file'
  rescue LoadError => e
    puts "LoadError: #{e}"
    puts "This Rakefile requires the rubyzip gem. Install it using: gem install rubyzip"
    exit(1)
  end
end

def unzip_file (file, destination)
  require_dependencies

  Zip::File.open(file) do |zip_file|
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

# Selectively copy files required for the telemetry client
# based on $telemetryClientInclude and $telemetryClientExclude
def telemetry_client_copy(fromDir, toDir)
  # Enumerate and store all included file paths
  included = []
  $telemetryClientInclude.each do |path|
    included.concat(Dir.glob(File.join(fromDir, path)))
  end
  
  # Enumerate and store all excluded file paths
  excluded = []
  $telemetryClientExclude.each do |path|
    excluded.concat(Dir.glob(File.join(fromDir, path)))
  end
  
  # Add .gitignore to excluded files
  excluded.concat IO.readlines(File.join(fromDir, ".gitignore")).map { |line|
    line.strip
  }.select { |line|
    line.length > 0 && !line.start_with?("#")
  }.map { |line|
    path = File.join(fromDir, line)
  }
  
  # Only process the included files without the excluded ones
  pathExcludedFiles = 0
  clientFiles = (included-excluded).select { |path| 
    sw = path.start_with? *excluded
    pathExcludedFiles += sw ? 1 : 0
    !sw
  }
  
  # Copy each file to the target directory
  clientFiles.each do |fromPath|
    toPath = fromPath.sub(fromDir, toDir)
    #puts "Copying #{fromPath} to #{toPath}"
    FileUtils.mkdir_p File.dirname(toPath)
    FileUtils.cp fromPath, toPath
  end
  
  puts "Copied #{clientFiles.length} Telemetry client files (included #{included.length}, excluded #{excluded.length}, path excluded #{pathExcludedFiles})"
  
end

desc "Build the Free SDK (desktop only)"
def prepare_free_sdk
  FileUtils.rm_rf "sdk/LoomDemo.app"
  FileUtils.rm_rf "sdk/LoomDemo.exe"
  FileUtils.rm_rf "pkg"

  telemetryClientPath = File.join("pkg/sdk/", $telemetryClient)

  # put together a folder to zip up
  FileUtils.mkdir_p "pkg/sdk"
  FileUtils.mkdir_p "pkg/sdk/bin"
  FileUtils.mkdir_p "pkg/sdk/libs"
  FileUtils.mkdir_p "pkg/sdk/assets"
  FileUtils.mkdir_p "pkg/sdk/src"
  FileUtils.mkdir_p telemetryClientPath
  
  # copy telemetry www
  telemetry_client_copy("tools/telemetry/www/", telemetryClientPath)
  
  #copy the docs in
  FileUtils.cp_r("artifacts/docs","pkg/sdk") if File.exists? "artifacts/docs"

  #copy the minimum cli version
  FileUtils.cp("MIN_CLI_VERSION", "pkg/sdk")

  # copy the libs
  FileUtils.cp_r("artifacts/libs", "pkg/sdk")

  if $LOOM_HOST_OS == "windows"
    FileUtils.cp_r("artifacts/windows-x86/", "pkg/sdk/bin")
    if HOST_ISX64 == '1'
      FileUtils.cp_r("artifacts/windows-x64/", "pkg/sdk/bin")
    end
  elsif $LOOM_HOST_OS == "linux"
    FileUtils.cp_r("artifacts/windows-x86/", "pkg/sdk/bin")
    if HOST_ISX64 == '1'
      FileUtils.cp_r("artifacts/windows-x64/", "pkg/sdk/bin")
    end
  else
    FileUtils.cp_r("artifacts/osx-x86/", "pkg/sdk/bin")
    # Strip out the bundled assets and binaries
    FileUtils.rm_rf "pkg/sdk/bin/osx-x86/LoomDemo.app/Contents/Resources/assets"
    FileUtils.rm_rf "pkg/sdk/bin/osx-x86/LoomDemo.app/Contents/Resources/bin"
    FileUtils.rm_rf "pkg/sdk/bin/osx-x86/LoomDemo.app/Contents/Resources/libs"
    if HOST_ISX64 == '1'
      FileUtils.cp_r("artifacts/osx-x64/", "pkg/sdk/bin")
      # Strip out the bundled assets and binaries
      FileUtils.rm_rf "pkg/sdk/bin/osx-x64/LoomDemo.app/Contents/Resources/assets"
      FileUtils.rm_rf "pkg/sdk/bin/osx-x64/LoomDemo.app/Contents/Resources/bin"
      FileUtils.rm_rf "pkg/sdk/bin/osx-x64/LoomDemo.app/Contents/Resources/libs"
    end
  end

  # copy ldb
  FileUtils.mkdir_p "pkg/sdk/TestExec/bin/"
  FileUtils.cp_r("artifacts/libs/TestExec.loom", "pkg/sdk/TestExec/bin/Main.loom")
  FileUtils.cp_r("artifacts/libs/TestExec.config", "pkg/sdk/TestExec/loom.config")

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

namespace :windows do
  def get_reg_value(keyname, valuename)
    access = Win32::Registry::KEY_READ
    begin
      Win32::Registry::HKEY_LOCAL_MACHINE::open(keyname, access) do |reg|
        reg.each{ |name, value| if name == valuename then return value end }
      end
    rescue
      return nil
    end
    return nil
  end

  def get_vs_name()
    if get_reg_value('SOFTWARE\Microsoft\VisualStudio\12.0', 'ShellFolder') != nil then
      return 'Visual Studio 12'
    end
    if get_reg_value('SOFTWARE\Wow6432Node\Microsoft\VisualStudio\12.0', 'ShellFolder') != nil then
      return 'Visual Studio 12'
    end
    if get_reg_value('SOFTWARE\Microsoft\VisualStudio\11.0', 'ShellFolder') != nil then
      return 'Visual Studio 11'
    end
    if get_reg_value('SOFTWARE\Wow6432Node\Microsoft\VisualStudio\11.0', 'ShellFolder') != nil then
      return 'Visual Studio 11'
    end
    if get_reg_value('SOFTWARE\Microsoft\VisualStudio\10.0', 'ShellFolder') != nil then
      return 'Visual Studio 10'
    end
    if get_reg_value('SOFTWARE\Wow6432Node\Microsoft\VisualStudio\10.0', 'ShellFolder') != nil then
       return 'Visual Studio 10'
    end
    if Dir.exists?(File.expand_path("#{ENV['programfiles']}\\Microsoft Visual Studio 12.0\\VC")) then
      return 'Visual Studio 12'
    end
    if Dir.exists?(File.expand_path("#{ENV['programfiles(x86)']}\\Microsoft Visual Studio 12.0\\VC")) then
      return 'Visual Studio 12'
    end
    if Dir.exists?(File.expand_path("#{ENV['programfiles']}\\Microsoft Visual Studio 11.0\\VC")) then
      return 'Visual Studio 11'
    end
    if Dir.exists?(File.expand_path("#{ENV['programfiles(x86)']}\\Microsoft Visual Studio 11.0\\VC")) then
      return 'Visual Studio 11'
    end
    if Dir.exists?(File.expand_path("#{ENV['programfiles']}\\Microsoft Visual Studio 10.0\\VC")) then
      return 'Visual Studio 10'
    end
    if Dir.exists?(File.expand_path("#{ENV['programfiles(x86)']}\\Microsoft Visual Studio 10.0\\VC")) then
      return 'Visual Studio 10'
    end
  end

end
