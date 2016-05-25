class Toolchain

  attr_reader :rebuild  
  
  def initialize()
    @rebuild = true
  end

  def buildCommand
    raise NotImplementedError
  end

  def name
    raise NotImplementedError
  end
  
  def description(target)
    return "#{target.buildType.to_s} #{name} #{arch(target)} #{target.is64Bit ? "64-bit" : "32-bit"}"
  end

  def cmakeArgs
    raise NotImplementedError
  end

  def arch(target)
    target.arch.to_s
  end
  
  def makeConfig(target)
    raise NotImplementedError
  end

  def executeCommand(cmd)
    # Uncomment to print commands before they are executed
    #puts "#{Dir.pwd}> #{cmd}";
    # Uncomment to make commands not actually execute - dry run
    #return;
    success = Kernel::system cmd
    if !success
      puts "Using working directory: #{Dir.pwd}"
      puts "Error 127 usually means command not found, make sure the following command is available" if $?.exitstatus == 127
      raise "Error #{$?.exitstatus}: #{cmd}"
    end
  end

  def build(target)
    path = target.buildPath(self)
    FileUtils.mkdir_p(path)
    Dir.chdir(path) do
      puts "cmake #{target.sourcePath} #{cmakeArgs(target)} #{target.flags(self)}"
      executeCommand("cmake #{target.sourcePath} #{cmakeArgs(target)} #{target.flags(self)}")
      executeCommand(buildCommand)
    end
  end

end

class WindowsToolchain < Toolchain

  def buildCommand
    return "msbuild /verbosity:m ALL_BUILD.vcxproj /p:Configuration=#{CFG[:BUILD_TARGET]}"
  end

  def name
    return "windows"
  end
  
  def makeConfig(target)
    return nil
  end
  
  def cmakeArgs(target)
    vs_install = get_vs_install
    abort("Missing or unsupported Visual Studio version") unless vs_install
    if target.is64Bit
      return "-G \"#{vs_install[:name]} Win64\""
    else
      return "-G \"#{vs_install[:name]}\""
    end
  end
  
  def get_reg_value(keyname, valuename)
    access = Win32::Registry::KEY_READ
    begin
      Win32::Registry::HKEY_LOCAL_MACHINE::open(keyname, access) do |reg|
        reg.each{ |name, value| if name == valuename then return reg[name] end }
      end
    rescue
      return nil
    end
    return nil
  end
  
  
  def get_vs_install()
  
    # Possible registry entries for Visual Studio
    regs = [
      { name: 'Visual Studio 14', path: 'SOFTWARE\Microsoft\VisualStudio\14.0' },
      { name: 'Visual Studio 14', path: 'SOFTWARE\Wow6432Node\Microsoft\VisualStudio\14.0' },
      { name: 'Visual Studio 12', path: 'SOFTWARE\Microsoft\VisualStudio\12.0' },
      { name: 'Visual Studio 12', path: 'SOFTWARE\Wow6432Node\Microsoft\VisualStudio\12.0' },
      { name: 'Visual Studio 11', path: 'SOFTWARE\Microsoft\VisualStudio\11.0' },
      { name: 'Visual Studio 11', path: 'SOFTWARE\Wow6432Node\Microsoft\VisualStudio\11.0' },
      { name: 'Visual Studio 10', path: 'SOFTWARE\Microsoft\VisualStudio\10.0' },
    ]
    
    # Default directory fallbacks
    dirs = [
      { name: 'Visual Studio 14', path: File.expand_path("#{ENV['programfiles']}\\Microsoft Visual Studio 14.0") },
      { name: 'Visual Studio 14', path: File.expand_path("#{ENV['programfiles(x86)']}\\Microsoft Visual Studio 14.0") },
      { name: 'Visual Studio 12', path: File.expand_path("#{ENV['programfiles']}\\Microsoft Visual Studio 12.0") },
      { name: 'Visual Studio 12', path: File.expand_path("#{ENV['programfiles(x86)']}\\Microsoft Visual Studio 12.0") },
      { name: 'Visual Studio 11', path: File.expand_path("#{ENV['programfiles']}\\Microsoft Visual Studio 11.0") },
      { name: 'Visual Studio 11', path: File.expand_path("#{ENV['programfiles(x86)']}\\Microsoft Visual Studio 11.0") },
      { name: 'Visual Studio 10', path: File.expand_path("#{ENV['programfiles']}\\Microsoft Visual Studio 10.0") },
      { name: 'Visual Studio 10', path: File.expand_path("#{ENV['programfiles(x86)']}\\Microsoft Visual Studio 10.0") },
    ]
    
    # VS2015 only supported on CMake >= 3.1
    if version_outdated?($CMAKE_VERSION, '3.1')
      regs.delete_if { |element| element[:name] == "Visual Studio 14" }
      dirs.delete_if { |element| element[:name] == "Visual Studio 14" }
    end

    # Check registry
    for reg in regs
      install = get_reg_value(reg[:path], 'ShellFolder')
      if install
        return { name: reg[:name], install: install }
      end
    end
    
    # Check dirs
    for dir in dirs
      if Dir.exists?(dir[:path])
        return { name: dir[:name], install: dir[:path] }
      end
    end
    
    # None found
    return nil
    
  end
end

class AppleToolchain < Toolchain
  # Combine several targets into one (e.g. lipo armv7, armv7s, arm64 into one arm)
  #   toolchain - the toolchain the targets were compiled under
  #   targets - an array of Targets to combine
  #   combined - the combined Target to produce a lib for
  def combine(toolchain, targets, combined)
    
    abort "Unable to combine architectures, no targets provided" unless targets.length > 0
    
    bin_out = combined.binPath(self)
    
    if File.file?(bin_out) and !toolchain.rebuild
      puts "Libraries already combined to #{pretty_path bin_out}, skipping..."
      return
    end
    
    puts "Combining libraries for #{toolchain.name}"
    
    libs = []
    libs_avail = []
    
    for target in targets
      lib = target.binPath(toolchain)
      exists = File.file?(lib)
      puts pretty_path lib
      puts "  #{toolchain.description(target)}: #{pretty_path lib}" + (exists ? "" : " (missing)")
      libs.push lib
      libs_avail.push lib unless !exists
    end
    
    abort "Unable to combine architectures, none exist: #{libs}" unless libs_avail.length > 0
    
    FileUtils.mkdir_p File.dirname(bin_out)
    
    if libs_avail.length == 1
      single = libs_avail[0]
      puts "Only one architecture available, copying from\n  #{pretty_path single} to\n  #{pretty_path bin_out}"
      FileUtils.cp single, bin_out
    else
      executeCommand("lipo -create \"#{libs_avail.join("\" \"")}\" -output \"#{bin_out}\"")
      puts "Combined to #{pretty_path bin_out}"
    end
    
  end
end

class OSXToolchain < AppleToolchain

  def name
    return "osx"
  end

  def makeConfig(target)
    return {
      CC: "gcc" + (target.is64Bit ? "" : " -m32")
    }
  end
  
  def buildCommand
    return "xcodebuild -configuration #{CFG[:BUILD_TARGET]}"
  end

  def cmakeArgs(target)
    return "-G \"Xcode\""
  end

end

class IOSToolchain < AppleToolchain

  def initialize(signAs)
    @signAs = signAs
    @sdkroot="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS#{CFG[:TARGET_IOS_SDK]}.sdk"
  end

  def name
    return "ios"
  end

  def makeConfig(target)
    clangTools = File.dirname(`xcrun -find clang`.chomp)
    sdkPath = `xcrun --sdk iphoneos --show-sdk-path`.chomp
    
    arch = target.arch.to_s
    flags = "-arch #{arch} -isysroot #{sdkPath}"
    
    return {
      HOST_CC: "xcrun clang" + ($ARCHS[target.arch][:is64Bit] ? "" : " -m32"),
      CC: "clang",
      CROSS: clangTools + "/",
      TARGET_FLAGS: flags,
      TARGET_SYS: "iOS"
    }
  end
  
  def buildCommand
    return "xcodebuild -configuration #{CFG[:BUILD_TARGET]} CODE_SIGN_IDENTITY=\"#{@signAs}\" CODE_SIGN_RESOURCE_RULES_PATH=#{@sdkroot}/ResourceRules.plist"
  end

  def cmakeArgs(target)
    return "-G \"Xcode\" -DLOOM_BUILD_IOS=1 -DLOOM_IOS_VERSION=#{CFG[:TARGET_IOS_SDK]}"
  end
  
end

class LinuxToolchain
end

class AndroidToolchain < Toolchain

  def buildCommand
    return "cmake --build ."
  end

  def name
    return "android"
  end
  
  def makeConfig(target)
    
    return nil unless !target.is64Bit
    
    systems = ["darwin-x86_64", "darwin-x86"]
    
    # Android/ARM, armeabi-v7a (ARMv7 VFP), Android 4.0+ (ICS)
    ndk = File.expand_path(ENV["ANDROID_NDK"])
    ndkABI = 14
    ndkVersion = "#{ndk}/toolchains/arm-linux-androideabi-4.6"
    ndkFound = false
    ndkSystems = []
    for system in systems
      ndkPath = "#{ndkVersion}/prebuilt/#{system}/bin/arm-linux-androideabi-"
      ndkDir = File.dirname(ndkPath)
      ndkSystems.push ndkDir
      if File.exists?(ndkDir)
        ndkFound = true
        break
      end
    end
    abort "Android NDK prebuilt directory not found, tried:\n  #{ndkSystems.join("\n  ")}" unless ndkFound
    ndkFlags = "--sysroot #{ndk}/platforms/android-#{ndkABI}/arch-arm"
    ndkArch = "-march=armv7-a -mfloat-abi=softfp -Wl,--fix-cortex-a8"
    
    return {
      CC: "gcc",
      HOST_CC: "gcc -m32",
      CROSS: ndkPath,
      TARGET_FLAGS: "#{ndkFlags} #{ndkArch}",
      TARGET_SYS: "Linux"
    }
  end

  def cmakeArgs(target)
    if $HOST.name == 'windows'
      generator = "MinGW Makefiles"
      make_arg = "-DCMAKE_MAKE_PROGRAM=\"%ANDROID_NDK%\\prebuilt\\#{$HOST.android_prebuilt_dir}\\bin\\make.exe\""
    else
      generator = "Unix Makefiles"
      make_arg = ""
    end

    return "-G \"#{generator}\" -DCMAKE_TOOLCHAIN_FILE=#{$ROOT}/build/cmake/loom.android.toolchain.cmake -DANDROID_NDK_HOST_X64=#{$HOST.is_x64} -DANDROID_ABI=armeabi-v7a -DANDROID_NATIVE_API_LEVEL=14 #{make_arg}"
  end
  
  def self.apkName()
    #Determine the APK name.
    if CFG[:TARGET_ANDROID_BUILD_TYPE] == "release"
      "LoomPlayer-release-unsigned.apk"
    elsif CFG[:TARGET_ANDROID_BUILD_TYPE] == "debug"
      "LoomPlayer-debug-unaligned.apk"
    else
      abort("Don't know how to generate the APK name for Android build target type #{CFG[:TARGET_ANDROID_BUILD_TYPE]}! Please update this if block.")
    end
  end
end


class MakeToolchain < Toolchain
  
  def initialize(platform)
    @platform = platform
  end
  
  def name
    return @platform.name
  end
  
  def description(target)
    return "make"
  end
  
  def arch(target)
    @platform.arch(target)
  end
  
  def getMakeArg(config, name)
    value = config[name]
    value ? "#{name.to_s}=\"#{value}\" " : ""
  end
  
  def build(target)
    
    config = @platform.makeConfig(target)
    
    buildDesc = @platform.description(target)
    
    if !config
      puts "#{buildDesc} unsupported, skipping..."
      return
    end
    
    Dir.chdir(target.sourcePath) do
      
      makeTarget = ""
      ccExtra = ""
      
      case target.buildType
      when :Release
        makeTarget = "amalg"
      when :Debug
        ccExtra += " -g"
      end
      
      ccExtra += target.flags(self)
      
      config[:CC] += ccExtra unless !config[:CC]
      config[:HOST_CC] += ccExtra unless !config[:HOST_CC]
      
      makeArgs = ""
      makeArgs += getMakeArg(config, :HOST_CC)
      makeArgs += getMakeArg(config, :CC)
      makeArgs += getMakeArg(config, :CROSS)
      makeArgs += getMakeArg(config, :TARGET_FLAGS)
      makeArgs += getMakeArg(config, :TARGET_SYS)
      
      prefix = target.buildName(self)
      buildRoot = target.buildRoot
      
      
      
      executeCommand "make clean"
      executeCommand "make -j #{makeTarget} BUILDMODE=static #{makeArgs} PREFIX=\"#{prefix}\""
      executeCommand "make install PREFIX=\"#{prefix}\" DESTDIR=\"#{buildRoot}/\""
    end
  end
end


class BatchToolchain < Toolchain
  
  attr_reader :platform
  
  def initialize(platform, path)
    @platform = platform
    @path = path
  end
  
  def name
    @platform.name
  end
  
  def description(target)
    pretty_path @path
  end
  
  def arch(target)
    @platform.arch(target)
  end
  
  def getMakeArg(config, name)
    nil
  end
  
  def build(target)
    cmd = @path + " " + target.flags(self)
    
    Dir.chdir(File.dirname(@path)) do
      executeCommand cmd
    end
  end
end
  
class LuaJITToolchain < Toolchain
  
  def initialize(buildToolchain, rebuild)
    @buildToolchain = buildToolchain
    @rebuild = rebuild
  end
  
  def name
    @buildToolchain.name
  end
  
  def description(target)
    "LuaJIT (#{super} #{@buildToolchain.description(target)} build)"
  end
  
  def arch(target)
    @buildToolchain.arch(target)
  end
  
  def build(target)
    
    path = target.buildPath(self)
    FileUtils.mkdir_p(path)
    
    lib = target.binPath(self)
    
    buildDesc = description(target)
    
    if File.file? lib and not @rebuild
      puts "#{buildDesc} already built at #{pretty_path lib}, skipping..."
      return
    end  
    
    if target.is64Bit && $HOST.is_x64 != '1'
      puts "#{buildDesc} unavailable, skipping..."
      return
    end
    
    puts "#{buildDesc} required, building..."
    
    @buildToolchain.build(target)
    
    if !File.file? lib
      abort "#{buildDesc} output missing at #{pretty_path lib}, build failed!"
    end
    
  end
end